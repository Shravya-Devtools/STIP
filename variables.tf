variable "region" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "s3_object_key" {
  type = string
}

variable "lambda_zip_path" {
  description = "Absolute path to the lambda ZIP provided by Octopus"
  type        = string
}

variable "api_gateway_name" {
  type = string
}

variable "lambda_configs" {
  description = "Lambda configuration map"
  type = map(object({
    method = string
    path   = string
  }))
}
