################################
# AWS
################################
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_name" {
  description = "Existing S3 bucket where Lambda ZIP will be uploaded"
  type        = string
}

variable "s3_object_key" {
  description = "S3 object key (path) for the Lambda ZIP"
  type        = string
}

################################
# Artifact from Octopus
################################
variable "lambda_zip_path" {
  description = "Local filesystem path to the Lambda ZIP extracted by Octopus"
  type        = string
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
