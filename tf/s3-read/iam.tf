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
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_reader_profile" {
  name = "s3_reader_profile"
  role = aws_iam_role.ec2_s3_reader_role.name
}
