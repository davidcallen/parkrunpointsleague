variable "project_name" {}
variable "project_id" {}
variable "billing_account" {}
variable "org_id" {}
variable "region" {
  type = "string"
  default = "europe-west2" 
}
variable "environment" {}

provider "google-beta" {
 region = "${var.region}"
}

resource "random_id" "id" {
 byte_length = 4
 prefix      = "${var.project_name}-"
}

resource "google_project" "project" {
 name            = "${var.project_name}"
 project_id      = "${var.project_id}"
 billing_account = "${var.billing_account}"
 org_id          = "${var.org_id}"
}

resource "google_project_services" "project" {
 project = "${google_project.project.project_id}"
 services = [
   "compute.googleapis.com",
   "servicenetworking.googleapis.com",
   "oslogin.googleapis.com"
 ]
}

output "project_id" {
 value = "${google_project.project.project_id}"
}

