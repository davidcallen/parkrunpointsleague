variable "environment" {
  description                     = "Environment details that are associated with the target AWS account"
  type = object({
    name                          = string        # Environment name (as used in account alias via switching roles) e.g. dev, demo, customerX-prod.
                                                  #    Name should be unique within our organistation
    account_id                    = string        # Environment account id
    resource_name_prefix          = string        # AWS Resource Name prefix
    resource_deletion_protection  = bool          # To protect against accidental deletion of resources
    default_tags                  = map(string)
  })
  default = {
    name                          = ""
    account_id                    = ""
    resource_name_prefix          = ""
    resource_deletion_protection  = true
    default_tags                  = {}
  }
}

