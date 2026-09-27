terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source = "hashicorp/google"
      # google_model_armor_template arrived in 6.43, floorsetting in 6.45, and
      # 7.x carries fixes for template permadiffs. Pinned to the 7 line.
      version = "~> 7.0"
    }
  }
}
