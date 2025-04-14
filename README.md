# NatWest AWS Infrastructure Deployment using Terraform and GitHub Actions

This project demonstrates the deployment of AWS infrastructure using Terraform, with automation integrated via GitHub Actions. The infrastructure includes an EC2 instance, S3 static website bucket, a Lambda function triggered by S3 events, and necessary IAM roles and permissions.

## Project Structure
. ├── main.tf - 
Core Terraform configuration

├── variables.tf - Input variable definitions

├── outputs.tf - Outputs such as instance IP, bucket URL 

├── scripts/

│ 
└── setup.sh - EC2 bootstrapping script (user data) 

├── lambda/ 
│ 
└── lambda.zip - Zipped AWS Lambda Python code

└── .github/ 

└── workflows/ 

└── terraform.yml - GitHub Actions workflow


## Tools and Technologies

| Tool/Service       | Purpose                                      |
|--------------------|----------------------------------------------|
| Terraform          | Infrastructure as Code (IaC)                 |
| AWS EC2            | Virtual machine hosting                      |
| AWS S3             | Static website hosting and event triggering  |
| AWS Lambda         | Function triggered by S3 events              |
| IAM                | Identity and access management               |
| GitHub Actions     | CI/CD pipeline for automated deployment      |

## GitHub Secrets Configuration

To authenticate Terraform with AWS in the GitHub Actions pipeline, the following secrets must be added in your GitHub repository settings:

| Secret Name        | Description                                 |
|--------------------|---------------------------------------------|
| `AWS_ACCESS_KEY`   | AWS IAM access key                          |
| `AWS_SECRET_KEY`   | AWS IAM secret access key                   |
| `AWS_REGION`       | AWS region (e.g., `us-east-1`)              |

Navigate to:  
**GitHub Repository > Settings > Secrets and Variables > Actions > New Repository Secret**

## Deployment Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/natwest-terraform-infra.git
   cd natwest-terraform-infra
Push the code to GitHub

bash
Copy
Edit
git add .
git commit -m "Initial commit"
git push origin main
CI/CD Execution

GitHub Actions will automatically execute terraform init, terraform plan, and terraform apply using the secrets provided.

AWS resources will be provisioned upon a successful run.

Outputs
After successful deployment, Terraform will provide:

Public IP of the EC2 instance

Static website endpoint URL of the S3 bucket

ARN of the Lambda function

Infrastructure Overview
EC2 Instance: Hosts a web server configured via a user data script.

S3 Bucket: Hosts static website files and triggers Lambda on object creation.

Lambda Function: Logs information upon S3 object uploads.

IAM Roles and Policies: Ensure secure access and permissions between services.

Teardown Instructions
To destroy the deployed resources and avoid incurring charges, run:

bash
Copy
Edit
terraform destroy -auto-approve
Common Errors and Troubleshooting
Error Message	Cause	Solution
Account is currently blocked	AWS account not verified or inactive	Contact AWS Support for account verification
BucketAlreadyExists	S3 bucket name is globally unique	Use a unique bucket name or add a random suffix
AccessDeniedException (Lambda)	Lambda role lacks required permissions	Ensure correct IAM role and policy attachment
SecurityGroup already exists	Duplicate security group name in same VPC	Modify name to be unique per deployment
Author
This project is submitted as part of an internship selection task. It showcases practical experience with cloud infrastructure deployment using Infrastructure as Code principles and CI/CD automation.
