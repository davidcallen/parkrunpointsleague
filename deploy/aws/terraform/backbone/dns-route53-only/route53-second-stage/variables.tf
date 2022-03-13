variable "backbone_vpc_id" {
  description = "The ID of the backbone VPC. To be associated with other accounts Route53 Private Hosted Zones"
  type        = string
  default     = ""
  validation {
    condition = length(var.backbone_vpc_id) > 0
    error_message = "Error : the variable 'backbone_private_zone_id' must be non-empty."
  }
}
variable "backbone_public_hosted_zone_id" {
  description = ""
  type        = string
  default     = ""
  validation {
    condition = length(var.backbone_public_hosted_zone_id) > 0
    error_message = "Error : the variable 'backbone_public_hosted_zone_id' must be non-empty."
  }
}
variable "other_account_public_hosted_zone_names" {
  description = "The Name of the other accounts Route53 public Hosted Zones. To create an NS record in our Backbone TLD PublicHZ"
  type        = list(string)
  default     = []
}
variable "other_account_public_hosted_zone_name_servers" {
  description = "The Name Servers of the other accounts Route53 public Hosted Zones. To create an NS record in our Backbone TLD PublicHZ"
  type        = list(string)
  default     = []
}
variable "other_account_private_hosted_zone_ids" {
  description = "The IDs of the other accounts Route53 Private Hosted Zones. To be associated with our Backbone VPC"
  type        = list(string)
  default     = []
}
