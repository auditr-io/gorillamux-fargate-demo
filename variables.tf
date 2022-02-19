variable "region" {
  type        = string
  default     = "us-west-2"
  description = "Target AWS region"
}

variable "profile" {
  type        = string
  description = "AWS profile"
}

variable "environment" {
  default = "dev"
  type    = string
}

variable "application" {
  type        = string
  default     = "gmuxdemo"
  description = "Application name"
}

variable "config_url" {
  type        = string
  default     = "https://config.auditr.io"
  description = "Config URL"
}

variable "api_key" {
  type        = string
  description = "API key"
  # sensitive   = true
}
