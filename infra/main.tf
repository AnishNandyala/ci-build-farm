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

module "ci_build_farm" {
  source        = "./modules/ci_build_farm"
  project_name  = var.project_name
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  max_agents    = var.max_agents
  instance_type = var.instance_type
  agent_image   = var.agent_image
}