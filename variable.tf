variable "do_token" {}
#variable "pvt_key" {}

variable "do_region" {
  type        = string
  default     = "fra1"
  description = "Digital Ocean classic droplets region of creation"
}
