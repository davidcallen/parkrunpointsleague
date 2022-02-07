resource "google_container_cluster" "prpl-cluster" {
  name     = "prpl-gke-cluster-${var.environment}"
  location = "${var.zone}"
  project  = "${var.project_id}"
  min_master_version = "1.13.7-gke.24"

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
  
  network = "prpl-network" 
  subnetwork = "prpl-subnet" 

  // private master config :
  //
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  ip_allocation_policy {
    // use_ip_aliases = true is required for private master
    //
    use_ip_aliases = true
  }

  // Use Stackdriver Logging
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  logging_service = "logging.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "prpl-node-pool" {
  name       = "prpl-node-pool"
  location   = "${var.region}"
  project    = "${var.project_id}"
  cluster    = "${google_container_cluster.prpl-cluster.name}"
  version    = "1.13.7-gke.24"
  node_count = 1

  node_config {
    preemptible  = "${var.preemptible-vms}"
    machine_type = "n1-standard-1"
    disk_size_gb = 10

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

resource "google_compute_network" "prpl-network" {
  name = "prpl-network" 
}

resource "google_compute_subnetwork" "prpl-subnet" {
  name          = "prpl-subnet"
  network       = google_compute_network.prpl-network.self_link
  ip_cidr_range = "10.180.0.0/20"
  region        = "europe-west2"
}

resource "google_compute_router" "prpl-router" {
  name    = "prpl-router"
  region  = google_compute_subnetwork.prpl-subnet.region
  network = google_compute_network.prpl-network.self_link
  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "prpl-nat" {
  name                               = "prpl-nat"
  router                             = google_compute_router.prpl-router.name
  region                             = "europe-west2"
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "default" {
  name    = "prpl-network-allow-ssh"
  network = "${google_compute_network.prpl-network.name}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
