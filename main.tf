############################
# Step 1: Download ZIP from JFrog
############################
resource "null_resource" "download_zip" {
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command = <<-EOT
$headers = @{
  Authorization = "Bearer ${trimspace(var.jfrog_password)}"
}
Invoke-WebRequest `
  -Uri "${trimspace(var.jfrog_url)}" `
  -Headers $headers `
  -OutFile "lambda.zip"
EOT
  }
}

############################
# Step 2: Upload ZIP to S3
############################
resource "aws_s3_object" "lambda_zip" {
  bucket = var.s3_bucket_name
  key    = var.s3_object_key
  source = "lambda.zip"

  depends_on = [null_resource.download_zip]
}

############################
# Step 3: USE EXISTING IAM ROLE & POLICY
############################

data "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
}

############################
# Step 4: Lambda Functions
############################
resource "aws_lambda_function" "lambda" {
  for_each = var.lambda_configs

  function_name = each.key
  role          = data.aws_iam_role.lambda_role.arn
  runtime       = "python3.10"
  handler       = "index.handler"

  s3_bucket = var.s3_bucket_name
  s3_key    = aws_s3_object.lambda_zip.key
}

############################
# Step 5: API Gateway
############################
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

############################
# Step 6: Integrations (ALL Lambdas)
############################
resource "aws_apigatewayv2_integration" "integration" {
  for_each = aws_lambda_function.lambda

  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = each.value.invoke_arn
}

############################
# Step 7: Routes
############################
resource "aws_apigatewayv2_route" "route" {
  for_each = var.lambda_configs

  api_id    = aws_apigatewayv2_api.api.id
  route_key = "${each.value.method} ${each.value.path}"
  target    = "integrations/${aws_apigatewayv2_integration.integration[each.key].id}"
}

############################
# Step 8: Stage
############################
resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

############################
# Step 9: Permissions
############################
resource "aws_lambda_permission" "allow_apigw" {
  for_each = aws_lambda_function.lambda

  statement_id  = "AllowApiGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
