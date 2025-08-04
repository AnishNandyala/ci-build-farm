import os, boto3

def handler(event, context):
    asg = boto3.client("autoscaling")
    name    = os.environ["ASG_NAME"]
    desired = int(os.environ["DESIRED_CAPACITY"])

    asg.set_desired_capacity(AutoScalingGroupName=name,
                             DesiredCapacity=desired,
                             HonorCooldown=False)

    return {"statusCode":200,"body":f"Scaling {name}→{desired}"}