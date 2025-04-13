provider "aws" {
 access_key = "AKIAW5BDREGJTS7K7AIE"
  secret_key = "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"
  region     = var.region
}

data "template_file" "user_data" {
  template = file("${path.module}/scripts/setup.sh")
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
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

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_http.id]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "WebServer"
  }
}

resource "aws_s3_bucket" "static_site" {
  bucket = var.bucket_name

  tags = {
    Name = "StaticSiteBucket"
  }
}

# Configure public access block settings
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket              = aws_s3_bucket.static_site.id
  block_public_acls   = false
  block_public_policy = false
}

# Website Configuration for the S3 bucket
resource "aws_s3_bucket_website_configuration" "static_site_website" {
  bucket = aws_s3_bucket.static_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_site.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_exec_role"

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

resource "aws_iam_policy_attachment" "lambda_logging" {
  name       = "attach_lambda_logging"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "s3_logger" {
  filename         = "lambda/lambda.zip"
  function_name    = "S3EventLogger"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda/lambda.zip")
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_logger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.static_site.arn
}

resource "aws_s3_bucket_notification" "bucket_notify" {
  bucket = aws_s3_bucket.static_site.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_logger.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
