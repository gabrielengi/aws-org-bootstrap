# backend-prod/main.tf

provider "aws" {
  region = "us-east-2" # REPLACE with your desired region for Dev resources
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "terraform_state_key" {
  description             = "KMS key for Prod Terraform state file encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  # Corrected 'policy' block for aws_kms_key.terraform_state_key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      # This statement allows the S3 service itself to use the key for encryption
      # This is critical for S3 bucket server-side encryption with KMS
      {
        Sid    = "Allow S3 to use the key for SSE"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
      # Removed the specific AWSReservedSSO_DeveloperAccess role from the key policy for initial creation.
      # The role Gabriel is assuming (DeveloperAccess) still needs kms:CreateKey in its *identity-based policy*.
    ]
  })
}

# 2. Create S3 Bucket (basic definition + tags)
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "prod-tf-states-bucket-20250615" # Keep changing this name if the bucket already exists!

  tags = {
    Name        = "Terraform State Bucket Prod" # REMOVED PARENTHESES
    Environment = "Prod"
    Project     = "Portfolio"
  }
}

# Add Versioning configuration
resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Add Server-Side Encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_sse" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state_key.arn
    }
  }
}

# PUBLIC ACCESS BLOCKING (this resource was correct)
resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_public_access" {
  bucket = aws_s3_bucket.terraform_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# 3. Create DynamoDB Table for Terraform State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "prod-tf-locks-20250615" # Keep changing this name if the table already exists!
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state_key.arn
  }

  tags = {
    Name        = "Terraform State Lock Table Prod" # REMOVED PARENTHESES
    Environment = "Prod"
    Project     = "Portfolio"
  }
}

# Output the S3 bucket and DynamoDB table names for easy reference
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state in Prod"
  value       = aws_s3_bucket.terraform_state_bucket.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform locks in Prod"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for Terraform state encryption in Prod"
  value       = aws_kms_key.terraform_state_key.arn
}