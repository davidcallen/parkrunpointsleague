terraform {
 backend "gcs" {
   bucket  = "prpl-terraform-state-97232"
   prefix  = "terraform/state"
 }
}
