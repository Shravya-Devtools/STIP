aws_region = "us-east-1"

s3_bucket_name = "terraform-state-devops-123456"
s3_object_key  = "websites/my-website/v1/lambda.zip"

api_gateway_name = "website-http-api"

lambda_configs = {
  STIPGetKeys = {
    method = "GET"
    path   = "/stip/get-keys"
  }

  STIPAccessToken = {
    method = "POST"
    path   = "/stip/access-token"
  }

  STIPLambda = {
    method = "POST"
    path   = "/stip/lambda"
  }
}
