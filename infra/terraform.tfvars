aws_region   = "us-east-1"
project_name = "ci-build-farm"
vpc_id       = "vpc-0123456789abcdef0"
subnet_ids   = ["subnet-aaa", "subnet-bbb"]
agent_image  = "yourdockerhub/ci-agent:latest"
# max_agents & instance_type can stay at default or be overridden here