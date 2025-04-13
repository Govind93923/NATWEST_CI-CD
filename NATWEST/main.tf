provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/setup.sh")
}

resource "aws_security_group" "allow_http_natwest" {
  name        = "allow_http_natwest"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_natwest" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_http_natwest.id]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "WebServer_Natwest"
  }
}

resource "aws_s3_bucket" "static_site_natwest" {
  bucket = var.bucket_name

  tags = {
    Name = "StaticSiteBucket_Natwest"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_natwest" {
  bucket              = aws_s3_bucket.static_site_natwest.id
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_website_configuration" "website_config_natwest" {
  bucket = aws_s3_bucket.static_site_natwest.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy_natwest" {
  bucket = aws_s3_bucket.static_site_natwest.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site_natwest.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role_natwest" {
  name = "lambda_s3_exec_role_natwest"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_logging_natwest" {
  name       = "attach_lambda_logging_natwest"
  roles      = [aws_iam_role.lambda_role_natwest.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "s3_logger_natwest" {
  filename         = "lambda/lambda.zip"
  function_name    = "S3EventLogger_Natwest"
  role             = aws_iam_role.lambda_role_natwest.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda/lambda.zip")
}

resource "aws_lambda_permission" "allow_s3_natwest" {
  statement_id  = "AllowExecutionFromS3Natwest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_logger_natwest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.static_site_natwest.arn
}

resource "aws_s3_bucket_notification" "bucket_notify_natwest" {
  bucket = aws_s3_bucket.static_site_natwest.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_logger_natwest.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3_natwest]
}
