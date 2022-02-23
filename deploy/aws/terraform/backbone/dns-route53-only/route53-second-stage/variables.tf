variable "backbone_vpc_id" {
  description = "The ID of the backbone VPC. To be associated with other accounts Route53 Private Hosted Zones"
  type        = string
  default     = ""
  validation {
    condition = length(var.backbone_vpc_id) > 0
    error_message = "Error : the variable 'backbone_private_zone_id' must be non-empty."
  }
}
variable "other_account_private_hosted_zone_ids" {
  description = "The IDs of the other accounts Route53 Private Hosted Zones. To be associated with our Backbone VPC"
  type        = list(string)
  default     = []
}
