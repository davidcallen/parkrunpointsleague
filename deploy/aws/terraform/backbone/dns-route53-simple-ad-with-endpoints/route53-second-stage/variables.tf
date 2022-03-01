variable "backbone_private_zone_id" {
  description = "The ID of the backbone Route53 Private Hosted Zone"
  type        = string
  default     = ""
  validation {
    condition = length(var.backbone_private_zone_id) > 0
    error_message = "Error : the variable 'backbone_private_zone_id' must be non-empty."
  }
}
variable "cross_account_vpc_ids" {
  description = "The VPC IDs from the cross-accounts. To be associated with our Backbone Route53 Private Hosted Zones"
  type        = list(string)
  default     = []
}
