variable "dns" {
  description = "DNS configuration"
  type = object({
    base_domain_name = string
    app_domain_name  = string
  })
}

variable "bucket_name" {
  type        = string
  default     = ""
  description = "Bucket name"
}
