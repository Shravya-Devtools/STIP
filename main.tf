############################################
# IAM ROLE (EXISTING)
############################################
data "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
}

############################################
# ZIP THE OCTOPUS-EXTRACTED FOLDER
############################################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = "${path.module}/lambda.zip"
}

############################################
# UPLOAD ZIP TO S3
############################################
resource "aws_s3_object" "lambda_zip" {
  bucket = var.s3_bucket_name
  key    = var.s3_object_key
  source = data.archive_file.lambda_zip.output_path

  etag = filemd5(data.archive_file.lambda_zip.output_path)
}

############################################
# LAMBDA FUNCTIONS
############################################
resource "aws_lambda_function" "lambda" {
  for_each = var.lambda_configs

  function_name = each.key
  role          = data.aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "index.handler"

  s3_bucket = var.s3_bucket_name
  s3_key    = var.s3_object_key

  depends_on = [aws_s3_object.lambda_zip]
}


output "debug_lambda_source_dir" {
  value = var.lambda_source_dir
}

