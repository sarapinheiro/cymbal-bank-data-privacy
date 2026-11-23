variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID where the demo will be deployed."
}

variable "region" {
  type        = string
  description = "The Google Cloud region for BigQuery, Cloud KMS, and Sensitive Data Protection."
  default     = "europe-west1"
}

variable "dataset_id" {
  type        = string
  description = "The BigQuery dataset ID for the retail banking datamart."
  default     = "cymbal_retail_banking"
}

variable "admin_user" {
  type        = string
  description = "The Google account email of the Risk & Compliance Analyst (Persona 1)."
}

variable "protect_table_on_apply" {
  type        = bool
  description = "Set to true to attach Policy Tags directly on table creation. Set to false if you want the table to start in the raw unprotected state for Demo 1 Step 1."
  default     = true
}
