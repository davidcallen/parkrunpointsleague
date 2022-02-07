variable "project_name" {}
variable "project_id" {}
variable "billing_account" {}
variable "org_id" {}
variable "region" {
  type = "string"
  default = "europe-west2" 
}
variable "zone" {
  type = "string"
  default = "europe-west2-a" 
}
variable "environment" {
  type = "string"
  description = "Environment description : e.g. dev, test, staging, production"
}
variable "preemptible-vms" {
  type = "string"
  default = "false"
  description = "Use pre-emptible VMs for cost-saving (warning : they can dissappear without warning and typically only last 24 hours)"
}

provider "google-beta" {
 region = "${var.region}"
}

/*
 * uncomment to also create the project

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

resource "google_project_services" "project_services" {
 project = "${google_project.project.project_id}"
 services = [
    "bigquery-json.googleapis.com",
    "bigquerystorage.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "servicenetworking.googleapis.com",
    "serviceusage.googleapis.com",
    "storage-api.googleapis.com"
 ]
}

output "project_id" {
 value = "${google_project.project.project_id}"
}
*/
