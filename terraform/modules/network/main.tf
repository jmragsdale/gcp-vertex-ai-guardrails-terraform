variable "project_id" {
  description = "Workload project."
  type        = string
}

variable "region" {
  description = "Subnet region."
  type        = string
}

variable "subnet_cidr" {
  description = "Primary range for the workload subnet."
  type        = string
}

locals {
  # restricted.googleapis.com: the VIP that only serves APIs supported by VPC
  # Service Controls. Routing Google APIs here means a workload cannot reach an
  # unsupported API that would sit outside the perimeter.
  restricted_vip = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
}

# NET-001  Custom-mode VPC. No auto-created subnets in regions nobody chose.
resource "google_compute_network" "genai" {
  project                 = var.project_id
  name                    = "genai-workload"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "genai" {
  project                  = var.project_id
  name                     = "genai-${var.region}"
  region                   = var.region
  network                  = google_compute_network.genai.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  # NET-004  Flow logs. Sampled at 0.5 to keep ingestion survivable; enough to
  # answer "did anything talk to somewhere it should not have".
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# NET-002  Default-deny egress. GCP's implied egress rule is allow-all, and a
# model that has been told to exfiltrate data needs an egress path to do it.
resource "google_compute_firewall" "deny_all_egress" {
  project            = var.project_id
  name               = "genai-deny-all-egress"
  network            = google_compute_network.genai.id
  direction          = "EGRESS"
  priority           = 65534
  destination_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# The one egress path: HTTPS to the restricted Google APIs VIP.
resource "google_compute_firewall" "allow_restricted_apis" {
  project            = var.project_id
  name               = "genai-allow-restricted-googleapis"
  network            = google_compute_network.genai.id
  direction          = "EGRESS"
  priority           = 1000
  destination_ranges = ["199.36.153.4/30"]

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# NET-005  Default-deny ingress, explicit and logged rather than implied.
resource "google_compute_firewall" "deny_all_ingress" {
  project       = var.project_id
  name          = "genai-deny-all-ingress"
  network       = google_compute_network.genai.id
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# NET-003  Resolve *.googleapis.com to the restricted VIP inside this VPC.
resource "google_compute_route" "restricted_apis" {
  project          = var.project_id
  name             = "genai-restricted-googleapis"
  network          = google_compute_network.genai.id
  dest_range       = "199.36.153.4/30"
  next_hop_gateway = "default-internet-gateway"
  priority         = 100
}

resource "google_dns_managed_zone" "googleapis" {
  project     = var.project_id
  name        = "genai-restricted-googleapis"
  dns_name    = "googleapis.com."
  description = "Routes Google APIs to restricted.googleapis.com (VPC-SC supported services only)."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.genai.id
    }
  }
}

resource "google_dns_record_set" "restricted_a" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "restricted.googleapis.com."
  type         = "A"
  ttl          = 300
  rrdatas      = local.restricted_vip
}

resource "google_dns_record_set" "googleapis_cname" {
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["restricted.googleapis.com."]
}

output "network_id" {
  description = "Workload VPC."
  value       = google_compute_network.genai.id
}
