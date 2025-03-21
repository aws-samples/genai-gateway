resource "aws_s3_bucket" "access_log_bucket" {
  bucket_prefix = "access-logs-"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.access_log_bucket.arn,
          "${aws_s3_bucket.access_log_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "AllowELBLogDelivery"
        Effect    = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.access_log_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "access_log_bucket" {
  bucket = aws_s3_bucket.access_log_bucket.id
  block_public_acls   = true
  block_public_policy = true
}