# scale_up_lambda.py
import json
import os
import traceback
import boto3
from datetime import datetime

asg_client = boto3.client("autoscaling")
sqs_client = boto3.client("sqs")
print("scale_up lambda loaded at", datetime.utcnow().isoformat())

def parse_event(event):
    """
    Support:
      - API Gateway (HTTP API v2) proxy events: event['body'] is JSON string
      - direct invoke where event is already a dict (body shape)
    Returns (body_dict, error_str)
    """
    if isinstance(event, dict) and "body" in event and event["body"] is not None:
        body_raw = event["body"]
        # If API gateway is sending base64-encoded body, event may also have isBase64Encoded flag.
        try:
            return json.loads(body_raw), None
        except Exception as e:
            return None, f"failed to parse event['body'] JSON: {e}"
    elif isinstance(event, dict):
        # direct invoke (or already parsed)
        return event, None
    else:
        return None, "unexpected event shape (not a dict)"

def build_response(status_code, payload):
    return {
        "statusCode": status_code,
        "body": json.dumps(payload)
    }

def handler(event, context):
    print("EVENT:", json.dumps(event, default=str))
    try:
        body, err = parse_event(event)
        if err:
            print("parse error:", err)
            return build_response(400, {"error": "invalid_request", "message": err})

        # Required fields for a job: repo and agents (agents may be 1+)
        repo = body.get("repo")
        agents = body.get("agents")
        branch = body.get("branch", "main")
        script = body.get("script", "run_tests.sh")
        job_id = body.get("job_id") or str(int(datetime.utcnow().timestamp()))

        missing = []
        if not repo:
            missing.append("repo")
        if agents is None:
            missing.append("agents")

        if missing:
            msg = f"missing required fields: {', '.join(missing)}"
            print(msg)
            return build_response(400, {"error": "missing_fields", "missing": missing, "message": msg})

        # Normalize agents -> int
        try:
            agents = int(agents)
            if agents < 1:
                raise ValueError("agents must be >= 1")
        except Exception as e:
            return build_response(400, {"error": "invalid_agents", "message": str(e)})

        # Determine ASG name & desired capacity
        asg_name = os.environ.get("ASG_NAME")  # prefer env var
        if not asg_name:
            return build_response(500, {"error": "server_config", "message": "ASG_NAME env not set"})

        desired_capacity = max(1, agents)  # simple policy: desired capacity = agents requested
        print(f"Scaling ASG {asg_name} -> {desired_capacity} (requested agents={agents})")

        # Call autoscaling: set desired capacity
        resp = asg_client.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=desired_capacity,
            HonorCooldown=False
        )
        print("set_desired_capacity response:", resp)

        # Optionally push job metadata to SQS so agents will pick it up
        # If you want this behavior, set JOB_QUEUE_URL env var; otherwise portal can post to queue separately.
        queue_url = os.environ.get("JOB_QUEUE_URL") or body.get("queue_url")
        if queue_url:
            msg_body = {
                "id": job_id,
                "repo": repo,
                "branch": branch,
                "script": script,
                "agents": agents
            }
            sqs_resp = sqs_client.send_message(QueueUrl=queue_url, MessageBody=json.dumps(msg_body))
            print("enqueued job to SQS:", sqs_resp)
        else:
            print("JOB_QUEUE_URL not provided; not enqueuing job (portal or other component should enqueue)")

        return build_response(200, {"job_id": job_id, "status": "scaling_started", "asg": asg_name, "desired_capacity": desired_capacity})

    except Exception as e:
        print("UNHANDLED EXCEPTION:", e)
        traceback.print_exc()
        return build_response(500, {"error": "internal_error", "message": str(e)})
