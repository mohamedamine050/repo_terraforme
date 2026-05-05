
# ─────────────────────────────────────────────────────────────────────────────
# Remote backend — state stored in S3, locking via DynamoDB
# (Provisioned by the bootstrap/ folder)
# ─────────────────────────────────────────────────────────────────────────────
terraform {
  backend "s3" {
    bucket         = "tfstate-infraetlspark-bk2545v7"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tflock-infraetlspark-bk2545v7"
    encrypt        = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Remote backend — state stored in S3, locking via DynamoDB
# (Provisioned by the bootstrap/ folder)
# ─────────────────────────────────────────────────────────────────────────────


terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_string" "suffix" {
  length  = 14
  upper   = false
  special = false
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "scripts" {
  bucket        = "data-pipeline-scripts-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name        = "data-pipeline-scripts-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket                  = aws_s3_bucket.scripts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "output" {
  bucket        = "data-pipeline-output-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name        = "data-pipeline-output-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "output" {
  bucket = aws_s3_bucket.output.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "output" {
  bucket = aws_s3_bucket.output.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "output" {
  bucket                  = aws_s3_bucket.output.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "glue_test_script" {
  bucket       = aws_s3_bucket.scripts.id
  key          = "scripts/glue_etl_test.py"
  content      = <<-EOT
print("Hello from TEST script")
EOT
  content_type = "text/x-python"
  etag         = md5(<<-EOT
print("Hello from TEST script")
EOT
  )
}

resource "aws_s3_object" "glue_second_script" {
  bucket       = aws_s3_bucket.scripts.id
  key          = "scripts/glue_etl_second.py"
  content      = <<-EOT
print("Hello from SECOND script")
EOT
  content_type = "text/x-python"
  etag         = md5(<<-EOT
print("Hello from SECOND script")
EOT
  )
}

resource "aws_iam_role" "glue_job" {
  name = "data-pipeline-glue-job-${random_string.suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "data-pipeline-glue-job-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "glue_job" {
  name = "data-pipeline-glue-job-${random_string.suffix.result}"
  role = aws_iam_role.glue_job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.scripts.arn,
          "${aws_s3_bucket.scripts.arn}/*",
          aws_s3_bucket.output.arn,
          "${aws_s3_bucket.output.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_glue_job" "etl" {
  name              = "data-pipeline-etl-${random_string.suffix.result}"
  role_arn          = aws_iam_role.glue_job.arn
  glue_version      = "5.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 60
  max_retries       = 0
  execution_class   = "STANDARD"

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/scripts/glue_etl_test.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--enable-metrics"                  = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--TempDir"                         = "s3://${aws_s3_bucket.output.bucket}/temp/"
    "--input_api_url"                   = var.external_api_url
    "--output_path"                     = "s3://${aws_s3_bucket.output.bucket}/output/"
  }

  tags = {
    Name        = "data-pipeline-etl-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_glue_job" "etl_second" {
  name              = "data-pipeline-etl-second-${random_string.suffix.result}"
  role_arn          = aws_iam_role.glue_job.arn
  glue_version      = "5.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  timeout           = 60
  max_retries       = 0
  execution_class   = "STANDARD"

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.bucket}/scripts/glue_etl_second.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                    = "python"
    "--enable-metrics"                  = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--TempDir"                         = "s3://${aws_s3_bucket.output.bucket}/temp/"
    "--input_api_url"                   = var.external_api_url
    "--output_path"                     = "s3://${aws_s3_bucket.output.bucket}/output-second/"
  }

  tags = {
    Name        = "data-pipeline-etl-second-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc" "rds" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "data-pipeline-rds-vpc-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "rds" {
  vpc_id            = aws_vpc.rds.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "data-pipeline-rds-subnet-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "rds_az2" {
  vpc_id            = aws_vpc.rds.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name        = "data-pipeline-rds-subnet-az2-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "data-pipeline-rds-${random_string.suffix.result}-"
  description = "RDS security group for data pipeline"
  vpc_id      = aws_vpc.rds.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "data-pipeline-rds-sg-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "data-pipeline-rds-subnet-group-${random_string.suffix.result}"
  subnet_ids = [aws_subnet.rds.id, aws_subnet.rds_az2.id]

  tags = {
    Name        = "data-pipeline-rds-subnet-group-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_db_instance" "rds" {
  identifier              = "data-pipeline-rds-${random_string.suffix.result}"
  allocated_storage       = var.rds_allocated_storage
  engine                  = var.rds_engine
  engine_version          = var.rds_engine_version
  instance_class          = var.rds_instance_class
  db_name                 = var.rds_db_name
  username                = var.rds_username
  password                = var.rds_password
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true
  storage_encrypted       = true
  backup_retention_period = 0
  multi_az                = false

  tags = {
    Name        = "data-pipeline-rds-${random_string.suffix.result}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}