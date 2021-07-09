variable "target_s3_bucket_name" {
  
}

variable "target_dynamodb_table_name" {
  
}

variable "target_sns_topic_name" {
  
}

variable "target_sqs_queue_name" {
  
}

resource "aws_iam_role" "ec2_s3_reader_role" {
  name = "ec2_s3_reader_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "read_s3_policy" {
  name = "ec2_s3_reader_role"
  role = aws_iam_role.ec2_s3_reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.target_s3_bucket_name}",
          "arn:aws:s3:::${var.target_s3_bucket_name}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "write_dynamodb_policy" {
  name = "write_dynamodb_policy"
  role = aws_iam_role.ec2_s3_reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:*",
        ]
        Effect   = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "write_sqs_policy" {
  name = "write_sqs_policy"
  role = aws_iam_role.ec2_s3_reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*",
        ]
        Effect   = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "write_sns_policy" {
  name = "write_sns_policy"
  role = aws_iam_role.ec2_s3_reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sns:*",
        ]
        Effect   = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "all_things_rds" {
  name = "all_things_rds"
  role = aws_iam_role.ec2_s3_reader_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:*",
        ]
        Effect   = "Allow"
        Resource = [
          "*",
        ]
      },
    ]
  })
}


resource "aws_iam_instance_profile" "ec2_s3_reader_profile" {
  name = "s3_reader_profile"
  role = aws_iam_role.ec2_s3_reader_role.name
}

output "s3_reader_profile_id" {
  value = aws_iam_instance_profile.ec2_s3_reader_profile.id
}