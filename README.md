AWS Org Bootstrap
This repository contains Terraform configurations for bootstrapping foundational AWS resources, primarily for managing Terraform state and providing state locking across different environments. It sets up secure, versioned S3 buckets for remote state and DynamoDB tables for state locking, encrypted with KMS keys.

Table of Contents
AWS Org Bootstrap
Table of Contents
Project Overview
Directory Structure
Features
Prerequisites
AWS CLI Configuration
Deployment
1. Development Environment (backend-dev)
2. Production Environment (backend-prod)
Outputs
Security Considerations
Contributors
License
Project Overview
This Terraform project focuses on establishing the core backend infrastructure required for managing Terraform state securely. It follows AWS best practices for state management, ensuring durability, versioning, encryption, and concurrency control across your AWS environments.

The project is structured to support multiple environments, starting with backend-dev for development and then extending to backend-prod for production.

Directory Structure
aws-org-bootstrap/
├── backend-dev/
│   └── main.tf       # Terraform config for Dev environment backend
├── backend-prod/
│   └── main.tf       # Terraform config for Prod environment backend (to be configured)
└── README.md         # This file
Features
This module currently provisions the following resources for each environment:

S3 Bucket for Terraform State:

Remote Backend: Configured as a remote backend for Terraform state files.
Versioning Enabled: Retains multiple versions of your state file, crucial for recovery from accidental deletions or errors.
Server-Side Encryption (SSE-KMS): Encrypts state files at rest using a dedicated AWS KMS Key.
Public Access Blocked: Ensures the bucket is not publicly accessible.
Tags: Standardized tagging for identification (Name, Environment, Project).
DynamoDB Table for State Locking:

State Locking: Prevents concurrent Terraform runs from corrupting your state file.
Pay-per-Request Billing: Cost-effective for low-to-medium usage.
Server-Side Encryption (SSE-KMS): Encrypts the table data at rest using the same dedicated KMS Key.
Tags: Standardized tagging for identification.
AWS KMS Key:

Dedicated Customer Master Key (CMK) for encrypting both the S3 bucket and DynamoDB table.
Key rotation enabled.
Policy configured to allow root account access and S3 service access for encryption.
Prerequisites
Before deploying these configurations, make sure you have:

AWS Account(s): Separate AWS accounts for Development and Production environments are highly recommended.
AWS IAM Identity Center (SSO) configured: This project assumes you're using AWS SSO for user management.
AWS CLI configured with SSO Profiles: You should have AWS CLI profiles configured for each environment (e.g., gabriel-dev, gabriel-prod) pointing to your AWS SSO setup.
Ensure your SSO permission set (e.g., DeveloperAccess) in the Development account has permissions to create KMS keys (kms:CreateKey, kms:PutKeyPolicy), S3 buckets (s3:CreateBucket, s3:PutBucketTagging, s3:PutBucketVersioning, s3:PutBucketServerSideEncryption), and DynamoDB tables (dynamodb:CreateTable, dynamodb:TagResource).
Terraform CLI: Install Terraform (v1.0.0 or higher recommended).
Git: Install Git for version control.
AWS CLI Configuration
Ensure your ~/.aws/config file has profiles configured for your environments via AWS SSO. For example:

Ini, TOML

[profile gabriel-dev]
sso_session = my-organization-sso
sso_account_id = 845997328611  # Your Development Account ID
sso_role_name = AWSReservedSSO_DeveloperAccess_XXXXXXXX # Your DeveloperAccess role suffix
region = us-east-2             # Dev region

[profile gabriel-prod]
sso_session = my-organization-sso
sso_account_id = 987654321098  # Your Production Account ID
sso_role_name = AWSReservedSSO_AdministratorAccess_YYYYYYYY # Your Prod Access role suffix
region = us-east-2             # Prod region

[sso-session my-organization-sso]
sso_start_url = https://d-xxxxxxxxxx.awsapps.com/start # Your AWS SSO start URL
sso_region = us-east-1 # Region where your SSO is configured
sso_registration_scopes = sso:account:access
Deployment
Always run terraform fmt and terraform plan before terraform apply.

1. Development Environment (backend-dev)
Navigate to the backend-dev directory:
Bash

cd backend-dev
Log in to your AWS SSO profile for the Development account:
Bash

aws sso login --profile gabriel-dev
Verify your identity: aws sts get-caller-identity (ensure it shows your Dev Account and DeveloperAccess role).
Set the AWS_PROFILE environment variable for Terraform:
Bash

export AWS_PROFILE="gabriel-dev"
(Or add profile = "gabriel-dev" directly to your provider "aws" block in main.tf).
Update Placeholders:
In main.tf, replace dev-tf-states-bucket-20250615 with a globally unique S3 bucket name (e.g., yourinitials-portfolio-dev-tf-states-uniqueid).
Replace dev-tf-locks-20250615 with a unique DynamoDB table name (e.g., yourinitials-portfolio-dev-tf-locks-uniqueid).
Ensure the region in the provider "aws" block is set to your desired region (e.g., us-east-2).
Initialize Terraform:
Bash

terraform init -upgrade
Review the plan:
Bash

terraform plan
Carefully examine the proposed changes.
Apply the configuration:
Bash

terraform apply
Confirm with yes when prompted.
2. Production Environment (backend-prod)
(This section will be completed once you configure the backend-prod/main.tf similar to backend-dev but with Production-specific names and configurations.)

Configure backend-prod/main.tf:
Copy the structure from backend-dev/main.tf.
Crucially, use unique names for the S3 bucket and DynamoDB table (e.g., prod-tf-states-bucket-UNIQUEID, prod-tf-locks-UNIQUEID).
Ensure the region in the provider "aws" block is set to your desired Production region.
Adjust tags to reflect "Prod" environment.
The KMS key policy might remain similar, or you might add a specific production deployment role to it.
Navigate to the backend-prod directory:
Bash

cd ../backend-prod
Log in to your AWS SSO profile for the Production account:
Bash

aws sso login --profile gabriel-prod
Verify your identity: aws sts get-caller-identity (ensure it shows your Prod Account and AdministratorAccess role).
Set the AWS_PROFILE environment variable:
Bash

export AWS_PROFILE="gabriel-prod"
Initialize Terraform:
Bash

terraform init -upgrade
Review the plan:
Bash

terraform plan
Apply the configuration:
Bash

terraform apply
Outputs
After successful deployment, Terraform will output the names and ARNs of the created resources for your reference, which are useful when configuring actual Terraform projects to use this backend.

Security Considerations
IAM Permissions: Ensure the IAM roles used for Terraform deployments have only the minimum necessary permissions (kms:CreateKey, s3:CreateBucket, dynamodb:CreateTable, etc.) rather than overly broad access, especially in production.
KMS Key Policy: The KMS key policy explicitly allows the root user and S3 service to use the key. For broader team access to the state files, you might consider adding specific IAM role ARNs (e.g., your SSO roles) to the KMS key policy after initial creation.
S3 Bucket Policy: While S3 Public Access Block is enabled, more granular access controls should be managed via IAM policies and potentially a precise S3 bucket policy if cross-account access is ever needed.
Contributors
[Your Name/GitHub Username] - Initial setup and configuration
License
This project is open-sourced under the MIT License. See the LICENSE file for details.
