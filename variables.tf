variable "aws_region" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_object_key" {
  type = string
}

variable "lambda_source_dir" {
  description = "Directory extracted by Octopus"
  type        = string
}

variable "api_gateway_name" {
  type = string
}

variable "lambda_configs" {
  type = map(object({
    method = string
    path   = string
  }))
}
