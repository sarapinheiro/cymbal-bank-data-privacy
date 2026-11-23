# ------------------------------------------------------------------------------
# Knowledge Catalog Taxonomy & Policy Tags
# ------------------------------------------------------------------------------

resource "google_data_catalog_taxonomy" "banking_governance" {
  display_name           = "Cymbal_Banking_Governance"
  description            = "Cymbal Bank 4-Tier Enterprise Data Classification Matrix (Confidencial, Restrito, Interno, Público)"
  activated_policy_types = ["FINE_GRAINED_ACCESS_CONTROL"]
  region                 = var.region
  project                = var.project_id
  depends_on             = [google_project_service.apis]
}

# Tier 1: Confidential PII
resource "google_data_catalog_policy_tag" "confidential_pii" {
  taxonomy     = google_data_catalog_taxonomy.banking_governance.id
  display_name = "Confidential_PII"
  description  = "Tier 1 (Confidencial): Sensitive PII & GDPR Protected Data"
}

# Tier 2: Restricted Banking Secret (Parent Tag)
resource "google_data_catalog_policy_tag" "restricted_banking_secret" {
  taxonomy     = google_data_catalog_taxonomy.banking_governance.id
  display_name = "Restricted_Banking_Secret"
  description  = "Tier 2 (Restrito): Banking Secrecy and Critical Identifiers"
}

# Tier 3: Internal Operational
resource "google_data_catalog_policy_tag" "interno_operational" {
  taxonomy     = google_data_catalog_taxonomy.banking_governance.id
  display_name = "Interno_Operational"
  description  = "Tier 3 (Interno): Internal Operational Banking Data"
}

# Tier 4: Public Open
resource "google_data_catalog_policy_tag" "publico_open" {
  taxonomy     = google_data_catalog_taxonomy.banking_governance.id
  display_name = "Publico_Open"
  description  = "Tier 4 (Público): Public Data"
}

# Granular Child Tags under Restricted_Banking_Secret for DDM
resource "google_data_catalog_policy_tag" "restricted_nif" {
  taxonomy          = google_data_catalog_taxonomy.banking_governance.id
  display_name      = "Restricted_NIF"
  description       = "Tax Identification Number (DDM Rule: SHA-256 Hash)"
  parent_policy_tag = google_data_catalog_policy_tag.restricted_banking_secret.id
}

resource "google_data_catalog_policy_tag" "restricted_iban" {
  taxonomy          = google_data_catalog_taxonomy.banking_governance.id
  display_name      = "Restricted_IBAN"
  description       = "Deposit IBAN (DDM Rule: Custom Masking ************)"
  parent_policy_tag = google_data_catalog_policy_tag.restricted_banking_secret.id
}

resource "google_data_catalog_policy_tag" "restricted_balance" {
  taxonomy          = google_data_catalog_taxonomy.banking_governance.id
  display_name      = "Restricted_Balance"
  description       = "Account Balance EUR (DDM Rule: NULLIFY)"
  parent_policy_tag = google_data_catalog_policy_tag.restricted_banking_secret.id
}

# ------------------------------------------------------------------------------
# Fine-Grained Reader IAM Bindings (Persona 1: Risk & Compliance Analyst)
# ------------------------------------------------------------------------------
resource "google_data_catalog_policy_tag_iam_binding" "fine_grained_reader" {
  for_each = {
    parent  = google_data_catalog_policy_tag.restricted_banking_secret.name
    nif     = google_data_catalog_policy_tag.restricted_nif.name
    iban    = google_data_catalog_policy_tag.restricted_iban.name
    balance = google_data_catalog_policy_tag.restricted_balance.name
  }

  policy_tag = each.value
  role       = "roles/datacatalog.categoryFineGrainedReader"
  members = [
    "user:${var.admin_user}"
  ]
}

# ------------------------------------------------------------------------------
# BigQuery Dynamic Data Masking (DDM) Policies
# ------------------------------------------------------------------------------

# 1. NIF -> SHA256 Hashing
resource "google_bigquery_datapolicy_data_policy" "ddm_nif_sha256" {
  location         = var.region
  project          = var.project_id
  data_policy_id   = "cymbal_ddm_nif_sha256"
  policy_tag       = google_data_catalog_policy_tag.restricted_nif.name
  data_policy_type = "DATA_MASKING_POLICY"

  data_masking_policy {
    predefined_expression = "SHA256"
  }
}

# 2. IBAN -> Custom Star Masking Routine
resource "google_bigquery_datapolicy_data_policy" "ddm_iban_mask" {
  location         = var.region
  project          = var.project_id
  data_policy_id   = "cymbal_ddm_iban_mask"
  policy_tag       = google_data_catalog_policy_tag.restricted_iban.name
  data_policy_type = "DATA_MASKING_POLICY"

  data_masking_policy {
    routine = google_bigquery_routine.mask_iban_stars.id
  }
}

# 3. Account Balance -> NULLIFY
resource "google_bigquery_datapolicy_data_policy" "ddm_balance_null" {
  location         = var.region
  project          = var.project_id
  data_policy_id   = "cymbal_ddm_balance_null"
  policy_tag       = google_data_catalog_policy_tag.restricted_balance.name
  data_policy_type = "DATA_MASKING_POLICY"

  data_masking_policy {
    predefined_expression = "ALWAYS_NULL"
  }
}

# ------------------------------------------------------------------------------
# Masked Reader IAM Bindings (Personas 2 & 3 receive masked results)
# ------------------------------------------------------------------------------
resource "google_bigquery_datapolicy_data_policy_iam_binding" "masked_readers" {
  for_each = {
    nif     = google_bigquery_datapolicy_data_policy.ddm_nif_sha256.data_policy_id
    iban    = google_bigquery_datapolicy_data_policy.ddm_iban_mask.data_policy_id
    balance = google_bigquery_datapolicy_data_policy.ddm_balance_null.data_policy_id
  }

  project        = var.project_id
  location       = var.region
  data_policy_id = each.value
  role           = "roles/bigquerydatapolicy.maskedReader"
  members = [
    "serviceAccount:${google_service_account.genai_agent.email}",
    "serviceAccount:${google_service_account.partner_portal.email}"
  ]
}
