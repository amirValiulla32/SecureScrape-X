variable "key_name" {
  description = "EC2 Key Pair Name"
  type        = string
}
variable "environment" {
  description = "Deployment environment (e.g. dev, prod)"
  type        = string
  default     = "dev"
}
