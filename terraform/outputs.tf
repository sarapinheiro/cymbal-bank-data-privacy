output "project_id" {
  description = "The GCP Project ID."
  value       = var.project_id
}

output "region" {
  description = "The deployment region."
  value       = var.region
}

output "bigquery_dataset" {
  description = "The retail banking BigQuery dataset."
  value       = google_bigquery_dataset.retail_banking.dataset_id
}

output "bigquery_table" {
  description = "The customer 360 table name."
  value       = "${google_bigquery_dataset.retail_banking.dataset_id}.${google_bigquery_table.customer_360.table_id}"
}

output "taxonomy_id" {
  description = "The Knowledge Catalog Taxonomy resource name."
  value       = google_data_catalog_taxonomy.banking_governance.id
}

output "policy_tag_nif" {
  description = "Resource name of the Restricted_NIF policy tag."
  value       = google_data_catalog_policy_tag.restricted_nif.name
}

output "policy_tag_iban" {
  description = "Resource name of the Restricted_IBAN policy tag."
  value       = google_data_catalog_policy_tag.restricted_iban.name
}

output "policy_tag_balance" {
  description = "Resource name of the Restricted_Balance policy tag."
  value       = google_data_catalog_policy_tag.restricted_balance.name
}

output "genai_agent_sa_email" {
  description = "Service Account email for GenAI Customer Assist Agent (Persona 2)."
  value       = google_service_account.genai_agent.email
}

output "partner_portal_sa_email" {
  description = "Service Account email for External Partner Portal (Persona 3)."
  value       = google_service_account.partner_portal.email
}

output "kms_key_ring_id" {
  description = "Cloud KMS Keyring ID."
  value       = google_kms_key_ring.envelope_keyring.id
}

output "kms_crypto_key_id" {
  description = "Cloud KMS CryptoKey ID."
  value       = google_kms_crypto_key.datamart_kek.id
}

output "sdp_inspect_template_id" {
  description = "Sensitive Data Protection inspection template ID."
  value       = google_data_loss_prevention_inspect_template.banking_inspection.id
}
