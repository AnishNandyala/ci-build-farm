import os
import boto3

def handler(event, context):
    asg_name = os.environ["ASG_NAME"]
    desired  = int(os.environ["DESIRED_CAPACITY"])
    client   = boto3.client("autoscaling")

    resp = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=desired,
        HonorCooldown=False
    )
    return {
        "statusCode": 200,
        "body": f"Scaled {asg_name} to {desired}"
    }