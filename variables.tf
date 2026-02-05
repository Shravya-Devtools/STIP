################################
# AWS
################################
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_name" {
  description = "Existing S3 bucket where Lambda ZIP is uploaded"
  type        = string
}

variable "s3_object_key" {
  description = "S3 object key (path) for the Lambda ZIP"
  type        = string
}

################################
# JFrog
################################
variable "jfrog_url" {
  description = "JFrog artifact ZIP download URL"
  type        = string
}

variable "jfrog_password" {
  description = "JFrog access token (Bearer token)"
  type        = string
  sensitive   = true
}

################################
# API Gateway
################################
variable "api_gateway_name" {
  description = "Name of the API Gateway HTTP API"
  type        = string
}

################################
# Lambda + API Routing
################################
variable "lambda_configs" {
  description = "Lambda name mapped to HTTP method and API path"
  type = map(object({
    method = string
    path   = string
  }))
}
