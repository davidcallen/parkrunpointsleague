resource "google_container_cluster" "prpl-cluster" {
  name     = "prpl-gke-cluster-${var.environment}"
  location = "${var.region}"
  project  = "${var.project_id}"
  min_master_version = "1.13.6-gke.13"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "prpl-node-pool" {
  name       = "prpl-node-pool"
  location   = "${var.region}"
  project    = "${var.project_id}"
  cluster    = "${google_container_cluster.prpl-cluster.name}"
  version    = "1.13.6-gke.13"
  node_count = 1

  node_config {
    preemptible  = "${var.preemptible-vms}"
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
