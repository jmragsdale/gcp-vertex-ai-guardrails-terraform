variable "parent" {
  description = "\"organizations/<id>\" or \"projects/<id>\". Org binding is inherited by every future project; project binding protects one."
  type        = string
}

variable "allowed_models" {
  description = "Allowed values for constraints/vertexai.allowedModels."
  type        = list(string)

  validation {
    condition     = length(var.allowed_models) > 0
    error_message = "An empty model allowlist would block every model. Name at least one."
  }
}

variable "cmek_required_services" {
  description = "Deny list for constraints/gcp.restrictNonCmekServices. Empty skips the constraint."
  type        = list(string)
  default     = []
}

variable "allowed_locations" {
  description = "Allowed values for constraints/gcp.resourceLocations, e.g. [\"in:us-locations\"]."
  type        = list(string)
}
