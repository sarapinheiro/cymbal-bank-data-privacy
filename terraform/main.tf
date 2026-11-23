terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.10.0, < 7.0.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.10.0, < 7.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  default_labels = {
    environment = "demo"
    managed_by  = "terraform"
    solution    = "cymbal-data-governance"
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
  default_labels = {
    environment = "demo"
    managed_by  = "terraform"
    solution    = "cymbal-data-governance"
  }
}

# ------------------------------------------------------------------------------
# 1. Enable Required GCP APIs
# ------------------------------------------------------------------------------
locals {
  services = [
    "bigquery.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "datacatalog.googleapis.com",
    "dataplex.googleapis.com",
    "dlp.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "securitycenter.googleapis.com"
  ]
}

resource "google_project_service" "apis" {
  for_each           = toset(local.services)
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# ------------------------------------------------------------------------------
# 2. Service Accounts for Demo Personas
# ------------------------------------------------------------------------------

# Persona 2: GenAI Customer Assist Agent
resource "google_service_account" "genai_agent" {
  account_id   = "sa-cymbal-genai-agent"
  display_name = "Cymbal Bank GenAI Customer Assist Agent"
  description  = "Service account for Vertex AI GenAI Agent (Persona 2: Masked/Hashed views)"
  depends_on   = [google_project_service.apis]
}

# Persona 3: External Partner Application
resource "google_service_account" "partner_portal" {
  account_id   = "sa-cymbal-partner-portal"
  display_name = "Cymbal Bank External Partner Portal"
  description  = "Service account for External Partner Portal (Persona 3: RLS filtered + Masked)"
  depends_on   = [google_project_service.apis]
}

# Grant BigQuery permissions to Service Accounts and Admin Analyst
resource "google_project_iam_member" "admin_bq_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "user:${var.admin_user}"
}

resource "google_project_iam_member" "genai_bq_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.genai_agent.email}"
}

resource "google_project_iam_member" "partner_bq_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.partner_portal.email}"
}

# Allow Admin User to impersonate the demo service accounts for testing
resource "google_service_account_iam_member" "admin_impersonate_genai" {
  service_account_id = google_service_account.genai_agent.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.admin_user}"
}

resource "google_service_account_iam_member" "admin_impersonate_partner" {
  service_account_id = google_service_account.partner_portal.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:${var.admin_user}"
}

# ------------------------------------------------------------------------------
# 3. Cloud KMS Keyring & KEK (Envelope Encryption Architecture)
# ------------------------------------------------------------------------------
resource "google_kms_key_ring" "envelope_keyring" {
  name       = "cymbal-envelope-keyring"
  location   = var.region
  project    = var.project_id
  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "datamart_kek" {
  name            = "cymbal-datamart-kek"
  key_ring        = google_kms_key_ring.envelope_keyring.id
  rotation_period = "7776000s" # 90 days
  purpose         = "ENCRYPT_DECRYPT"
}
