# S3 bucket for VPC Flow Logs (cheaper & longer retention than CW Logs)
resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "flow_logs" {
  bucket = "${var.name}-vpc-flowlogs-${random_id.suffix.hex}"
  tags   = local.tags
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  rule {
    id     = "expire-noncurrent-and-logs"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    expiration {
      days = 365
    }
  }
}
