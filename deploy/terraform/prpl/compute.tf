data "google_compute_image" "prpl-service" {
  family  = "prpl"
  project = "${var.project_id}"
}
resource "google_compute_instance_template" "prpl-service" {
  name_prefix    = "prpl-service-"
  machine_type   = "f1-micro"
  can_ip_forward = false
  labels = {
    service = "prpl-service"
    environment = "${var.environment}"
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  disk {
    source_image = "${data.google_compute_image.prpl-service.self_link}"
    disk_type    = "pd-standard"
    disk_size_gb = 10
    auto_delete  = true
    boot         = true
  }
  network_interface {
    network       = "default"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "prpl-service" {
  provider           = "google-beta"
  name               = "prpl-service-manager"
  base_instance_name = "prpl-service"

  version {
    name= "prpl-instance-version"
    instance_template = "${google_compute_instance_template.prpl-service.self_link}"
  }
  
  # update_strategy   = "ROLLING"
  zone              = "europe-west2-a"
  target_size       = 3
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}
