############################################
resource "null_resource" "jfrog_to_s3" {
  triggers = {
    artifact_url = var.jfrog_url
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail

echo "Downloading from JFrog and uploading to S3..."

curl -fL \
  -H "Authorization: Bearer ${trimspace(var.jfrog_password)}" \
  "${trimspace(var.jfrog_url)}" \
| aws s3 cp - s3://${var.s3_bucket_name}/${var.s3_object_key}

echo "Verifying object exists in S3..."
aws s3 ls s3://${var.s3_bucket_name}/${var.s3_object_key}
EOT
  }
}

############################
# Step 3: USE EXISTING IAM ROLE
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
  s3_key    = var.s3_object_key

  # Critical: Wait for the S3 upload to finish before trying to create Lambda
  depends_on = [null_resource.jfrog_to_s3]
}

############################
# Step 5: API Gateway
############################
resource "aws_apigatewayv2_api" "api" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

############################
# Step 6: Integrations
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
# Step 9: Lambda Permissions
############################
resource "aws_lambda_permission" "allow_apigw" {
  for_each = aws_lambda_function.lambda

  statement_id  = "AllowApiGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}
