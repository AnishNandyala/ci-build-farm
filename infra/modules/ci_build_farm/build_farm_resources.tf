##### SQS Queue #####

resource "aws_sqs_queue" "job_queue" {
  name = "${var.project_name}-jobs"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
}

##### IAM #####

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "ec2_inline" {
  name   = "${var.project_name}-agent-inline"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ec2_policy.json
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    sid    = "AllowSQSPolling"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [ aws_sqs_queue.job_queue.arn ]
  }
  statement {
    sid    = "AllowS3Artifacts"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.project_name}-artifacts",
      "arn:aws:s3:::${var.project_name}-artifacts/*"
    ]
  }
  statement {
    sid    = "AllowCWLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-agent-profile"
  role = aws_iam_role.ec2_role.name
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda_autoscaling" {
  name = "${var.project_name}-lambda-autoscaling"
  role = aws_iam_role.lambda_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action":[
        "autoscaling:SetDesiredCapacity",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect":"Allow",
      "Action":[
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.job_queue.arn}"
    }
  ]
}
POLICY
}

##### Auto Scaling Group #####

resource "aws_autoscaling_group" "agents" {
  name                      = "${var.project_name}-asg"
  max_size                  = var.max_agents
  min_size                  = 0
  desired_capacity          = 0

  vpc_zone_identifier       = var.subnet_ids

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id      = aws_launch_template.agent_lt.id
        version = "$Latest"
      }
    }
    instances_distribution {
      spot_instance_pools                      = 2
      on_demand_percentage_above_base_capacity = 20
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-agent"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

##### EC2 Instance Launch Template and Image #####

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_launch_template" "agent_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(
    templatefile("${path.module}/user_data.tpl", {
      queue_url   = aws_sqs_queue.job_queue.id
      agent_image = var.agent_image
      aws_region    = var.aws_region
      project_name  = var.project_name
      artifacts_bucket_id = var.artifacts_bucket_id
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-agent"
    }
  }
}

##### Lambda #####

data "archive_file" "scale_up_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scale_up_lambda.py"
  output_path = "${path.module}/lambdas/scale_up.zip"
}

data "archive_file" "scale_down_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/scale_down_lambda.py"
  output_path = "${path.module}/lambdas/scale_down.zip"
}

resource "aws_lambda_function" "scale_up" {
  function_name = "${var.project_name}-scale-up"
  handler       = "scale_up_lambda.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn

  filename      = data.archive_file.scale_up_zip.output_path
  source_code_hash = data.archive_file.scale_up_zip.output_base64sha256

  environment {
    variables = {
      ASG_NAME        = aws_autoscaling_group.agents.name
      DESIRED_CAPACITY = tostring(var.max_agents)
      ASG_READY_TIMEOUT  = tostring(var.asg_ready_timeout)
      ASG_POLL_INTERVAL  = tostring(var.asg_poll_interval)
    }
  }
}

resource "aws_lambda_function" "scale_down" {
  function_name = "${var.project_name}-scale-down"
  handler       = "scale_down_lambda.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn

  filename      = data.archive_file.scale_down_zip.output_path
  source_code_hash = data.archive_file.scale_down_zip.output_base64sha256

  environment {
    variables = {
      ASG_NAME = aws_autoscaling_group.agents.name
    }
  }
}

##### S3 Bucket Trigger & Notification #####

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_down.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.artifacts_bucket_arn
}


##### CloudWatch Alarms #####

resource "aws_cloudwatch_metric_alarm" "scale_down_on_empty" {
  alarm_name          = "${var.project_name}-scale-down-on-empty"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  comparison_operator = "LessThanThreshold"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.job_queue.name
  }

  alarm_actions = [
    aws_sns_topic.scale_down.arn
  ]

  treat_missing_data = "notBreaching"
}

##### SNS #####

resource "aws_sns_topic" "scale_down" {
  name = "${var.project_name}-scale-down"
}

resource "aws_sns_topic_subscription" "scale_down_lambda" {
  topic_arn = aws_sns_topic.scale_down.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scale_down.arn
}

resource "aws_lambda_permission" "allow_sns_invoke_scale_down" {
  statement_id  = "AllowSNSInvokeScaleDown"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scale_down.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.scale_down.arn
}