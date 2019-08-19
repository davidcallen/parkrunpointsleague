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
  
  named_port {
    name = "http"
    port = 8080
  }

  # update_strategy   = "ROLLING"
  zone              = "europe-west2-a"
  target_size       = 2
  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}

resource "google_compute_global_address" "prpl-service" {
  name = "prpl-service-address"
}

resource "google_compute_health_check" "prpl-service" {
  name               = "prpl-service-healthcheck"
  check_interval_sec = 5
  timeout_sec        = 1
  http_health_check {
    port         = "8080"
    request_path = "/health"
  }
}

resource "google_compute_backend_service" "my-service" {
  name          = "my-backend-service"
  port_name     = "http"
  protocol      = "HTTP"
  health_checks = ["${google_compute_health_check.prpl-service.self_link}"]
  backend {
    group = "${google_compute_instance_group_manager.prpl-service.instance_group}"
  }
  iap {
    oauth2_client_id     = "265388892072-bk02net84sc0bs60iiur59tr92uj83n2.apps.googleusercontent.com"
    oauth2_client_secret = "r7ASew1QUTvuhrNO1x1N_vIi"
  }
}

resource "google_compute_url_map" "prpl-service" {
  name            = "prpl-service-url-map"
  default_service = "${google_compute_backend_service.my-service.self_link}"
}

# openssl req -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out cert.pem
resource "google_compute_ssl_certificate" "prpl-service" {
  name        = "prpl-service-certificate"
  description = "My Service certificate"
  private_key = "${file("files/key.pem")}"
  certificate = "${file("files/cert.pem")}"
}

resource "google_compute_target_https_proxy" "prpl-service" {
  name             = "prpl-service-https-proxy"
  url_map          = "${google_compute_url_map.prpl-service.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.prpl-service.self_link}"]
}

resource "google_compute_global_forwarding_rule" "prpl-service" {
  name       = "prpl-service-forwarding-rule-https"
  port_range = "443"
  ip_address = "${google_compute_global_address.prpl-service.address}"
  target     = "${google_compute_target_https_proxy.prpl-service.self_link}"
}
