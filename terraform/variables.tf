variable "project_id" {
  type        = string
  description = "The globally unique ID of the GCP project"
}


variable "region" {
  type        = string
  description = "The GCP region for regional resources"
  default     = "us-central1"
}

variable "spanner_instance_name" {
  type        = string
  description = "The name of the Spanner instance"
  default     = "dsg-spanner"
}

variable "spanner_instance_display_name" {
  type        = string
  description = "The display name of the Spanner instance"
  default     = "DSG Spanner Instance"
}

variable "spanner_config" {
  type        = string
  description = "The Spanner instance configuration"
  default     = "regional-us-central1"
}

variable "spanner_processing_units" {
  type        = number
  description = "Processing units for the Spanner instance (multiples of 100)"
  default     = 100
}
