# CI Build Farm Self-Service Portal

A turnkey, cost-optimized CI build-farm on AWS that lets teams spin up on-demand build agents with zero idle cost. Built with Terraform, Lambda, API Gateway, SQS, Spot EC2, and a React front-end, this solution automates the entire lifecycle—from provisioning to teardown—via a simple web portal.

## 🚀 Key Features

- **Self-Service Portal**  
  React + S3/CloudFront UI for team members to configure repo, branch & agent image and hit “Deploy.”

- **Terraform-Backed IaC**  
  Modular Terraform code to provision VPC, S3, SQS, ASG (Spot Instances), IAM roles, and Lambda functions.

- **Automatic Scaling & Teardown**  
  Spot EC2 ASG with desired_capacity=0 by default; Lambdas to scale up on demand and scale down on S3 artifact creation.

- **Secure, Cost-Efficient**  
  Least-privilege IAM roles, on-demand build agents (70–90% spot savings), and zero idle compute charges.

## ⚙️ Architecture

1. **Portal** (React on S3/CF) → 2. **API Gateway + Lambda** → 3. **Terraform Apply** →  
4. **SQS + Spot ASG + User Data** → 5. **Build Agents** → 6. **S3 Artifacts** → 7. **Scale-Down Lambda**

## 🔧 Getting Started

1. **Clone** this repo  
2. **Configure** `infra/terraform.tfvars` (AWS region, project name, max agents, agent Docker image)  
3. **Deploy**  
   ```bash
   ./deploy.sh
4. **Open** the portal at `https://<your-domain>` and click **Deploy Build Farm**
5. **Clean up** when done:
   ```bash
   ./destroy.sh