resource "aws_sqs_queue" "job_queue" {
  name = "${var.project_name}-jobs"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
}

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

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-agent-profile"
  role = aws_iam_role.ec2_role.name
}

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
    })
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-agent"
    }
  }
}