variable "authorized_ips" {
  description = "Authorized CIDRs for storage account management (outbound IP is automatically included)."
  type        = list(string)
  default     = []
}

variable "subscription_id" {
  description = "Azure Subscription ID."
  type        = string
}

variable "tags" {
  description = "Tags to be applied to Azure resources."
  type        = map(string)
}
