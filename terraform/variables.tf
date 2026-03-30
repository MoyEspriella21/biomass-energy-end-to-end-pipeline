variable "project" {
  description = "ID del proyecto de GCP"
  default     = "biomass-energy-491402"
  type        = string
}

variable "region" {
  description = "Región de los recursos"
  default     = "us-central1"
  type        = string
}

variable "location" {
  description = "Ubicación geográfica general para BigQuery y Cloud Storage"
  default     = "US"
  type        = string
}

variable "bq_dataset_name" {
  description = "Nombre del dataset en BigQuery"
  default     = "biomass_analytics_dataset"
  type        = string
}

variable "gcs_bucket_name" {
  description = "Nombre del bucket en Cloud Storage"
  default     = "data-lake-biomass-491402"
  type        = string
}
