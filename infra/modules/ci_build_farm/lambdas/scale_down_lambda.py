import os
import boto3

def handler(event, context):
    asg_name = os.environ["ASG_NAME"]
    client   = boto3.client("autoscaling")

    resp = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=0,
        HonorCooldown=False
    )
    return {
        "statusCode": 200,
        "body": f"Scaled {asg_name} down to 0"
    }