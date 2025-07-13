terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.18.0"
    }
  }

  backend "s3" {
    bucket         = "ci-build-farm-tfstate-bucket"
    key            = "ci-build-farm/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-locks"
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "ci_build_farm" {
  source        = "./modules/ci_build_farm"
  aws_region    = var.aws_region
  project_name  = var.project_name
  vpc_id        = data.aws_vpc.default.id
  subnet_ids    = data.aws_subnets.default.ids
  max_agents    = var.max_agents
  instance_type = var.instance_type
  agent_image   = var.agent_image

  artifacts_bucket_arn = module.ci_build_artifacts.bucket_arn
  artifacts_bucket_id  = module.ci_build_artifacts.bucket_id
}

module "ci_build_artifacts" {
  source = "./modules/artifacts_bucket"
  aws_region = var.aws_region
  project_name = var.project_name
}