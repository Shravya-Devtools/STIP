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
  source_dir = var.lambda_source_dir
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

############################################
# API GATEWAY
############################################
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

############################################
# API INTEGRATIONS
############################################
resource "aws_apigatewayv2_integration" "integration" {
  for_each = aws_lambda_function.lambda

  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = each.value.invoke_arn
}

############################################
# ROUTES
############################################
resource "aws_apigatewayv2_route" "route" {
  for_each = var.lambda_configs

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.integration[each.key].id}"
}

############################################
# STAGE
############################################
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

############################################
# LAMBDA PERMISSIONS
############################################
resource "aws_lambda_permission" "allow_apigw" {
  for_each = aws_lambda_function.lambda

  statement_id  = "AllowApiGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
