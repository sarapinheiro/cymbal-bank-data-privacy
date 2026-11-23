# ------------------------------------------------------------------------------
# BigQuery Datamart & Schema Setup
# ------------------------------------------------------------------------------

resource "google_bigquery_dataset" "retail_banking" {
  dataset_id                  = var.dataset_id
  friendly_name               = "Cymbal Retail Banking"
  description                 = "Cymbal Bank Retail Banking Datamart - Production Mirror for Security & Governance Validation"
  location                    = var.region
  project                     = var.project_id
  delete_contents_on_destroy  = true
  depends_on                  = [google_project_service.apis]
}

# Dataset IAM Grants for Demo Personas
resource "google_bigquery_dataset_iam_member" "admin_access" {
  dataset_id = google_bigquery_dataset.retail_banking.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "user:${var.admin_user}"
}

resource "google_bigquery_dataset_iam_member" "genai_viewer" {
  dataset_id = google_bigquery_dataset.retail_banking.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.genai_agent.email}"
}

resource "google_bigquery_dataset_iam_member" "partner_viewer" {
  dataset_id = google_bigquery_dataset.retail_banking.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.partner_portal.email}"
}

# Custom Masking Routine for IBAN
resource "google_bigquery_routine" "mask_iban_stars" {
  dataset_id      = google_bigquery_dataset.retail_banking.dataset_id
  routine_id      = "mask_iban_stars"
  routine_type    = "SCALAR_FUNCTION"
  language        = "SQL"
  definition_body = "CONCAT(SUBSTR(val, 1, 4), '************', SUBSTR(val, -2))"
  return_type     = "{\"typeKind\": \"STRING\"}"

  arguments {
    name      = "val"
    data_type = "{\"typeKind\": \"STRING\"}"
  }
}

# ------------------------------------------------------------------------------
# Customer 360 Core Banking Table
# ------------------------------------------------------------------------------
locals {
  # Schema with Policy Tags attached (Protected State)
  schema_protected = jsonencode([
    {
      name        = "customer_id"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Unique internal customer identifier"
    },
    {
      name        = "full_name"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Customer full legal name"
    },
    {
      name        = "portugal_nif"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Portuguese Tax Identification Number (NIF)"
      policyTags = {
        names = [google_data_catalog_policy_tag.restricted_nif.name]
      }
    },
    {
      name        = "iban"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Customer primary deposit IBAN (PT500099...)"
      policyTags = {
        names = [google_data_catalog_policy_tag.restricted_iban.name]
      }
    },
    {
      name        = "account_balance"
      type        = "NUMERIC"
      mode        = "NULLABLE"
      description = "Aggregated checking & savings balance in EUR"
      policyTags = {
        names = [google_data_catalog_policy_tag.restricted_balance.name]
      }
    },
    {
      name        = "risk_segment"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Internal AML/Credit risk score category"
    },
    {
      name        = "branch_code"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Home branch identifier (e.g. 0099 for Central Headquarters)"
    },
    {
      name        = "email"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Registered customer contact email"
    }
  ])

  # Schema without Policy Tags (Raw State for Demo 1 Step 1)
  schema_unprotected = jsonencode([
    {
      name        = "customer_id"
      type        = "INTEGER"
      mode        = "NULLABLE"
      description = "Unique internal customer identifier"
    },
    {
      name        = "full_name"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Customer full legal name"
    },
    {
      name        = "portugal_nif"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Portuguese Tax Identification Number (NIF)"
    },
    {
      name        = "iban"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Customer primary deposit IBAN (PT500099...)"
    },
    {
      name        = "account_balance"
      type        = "NUMERIC"
      mode        = "NULLABLE"
      description = "Aggregated checking & savings balance in EUR"
    },
    {
      name        = "risk_segment"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Internal AML/Credit risk score category"
    },
    {
      name        = "branch_code"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Home branch identifier (e.g. 0099 for Central Headquarters)"
    },
    {
      name        = "email"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Registered customer contact email"
    }
  ])
}

resource "google_bigquery_table" "customer_360" {
  dataset_id          = google_bigquery_dataset.retail_banking.dataset_id
  table_id            = "customer_360"
  description         = "Cymbal Bank Customer 360 Core Banking View - High Value Asset with PII and Financial Secrets"
  deletion_protection = false

  schema = var.protect_table_on_apply ? local.schema_protected : local.schema_unprotected

  depends_on = [
    google_data_catalog_policy_tag.restricted_nif,
    google_data_catalog_policy_tag.restricted_iban,
    google_data_catalog_policy_tag.restricted_balance
  ]
}

# Seed realistic Portuguese banking records into customer_360
resource "google_bigquery_job" "seed_customer_data" {
  job_id   = "seed_customer_360_${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location = var.region

  query {
    query              = <<-SQL
      INSERT INTO `${var.project_id}.${google_bigquery_dataset.retail_banking.dataset_id}.${google_bigquery_table.customer_360.table_id}`
        (customer_id, full_name, portugal_nif, iban, account_balance, risk_segment, branch_code, email)
      VALUES
        (1001, 'António Silva', '214872912', 'PT50009900990001234567877', 84320.50, 'LOW', '0099', 'antonio.silva@cymbal-client.com'),
        (1002, 'Maria Santos', '189234810', 'PT50009900990002345678988', 12450.80, 'MEDIUM', '0099', 'maria.santos@cymbal-client.com'),
        (1003, 'Carlos Ferreira', '258102934', 'PT50009900120003456789099', 310.20, 'HIGH', '0012', 'carlos.ferreira@cymbal-client.com'),
        (1004, 'Ana Oliveira', '201928374', 'PT50009900990004567890111', 215400.00, 'LOW', '0099', 'ana.oliveira@cymbal-client.com'),
        (1005, 'Rui Sousa', '172839401', 'PT50009900440005678901222', 45.00, 'HIGH', '0044', 'rui.sousa@cymbal-client.com');
    SQL
    use_legacy_sql     = false
    create_disposition = "CREATE_NEVER"
    write_disposition  = "WRITE_EMPTY"
  }

  depends_on = [google_bigquery_table.customer_360]

  lifecycle {
    ignore_changes = [job_id]
  }
}

# Row-Level Security Policies for Demo 2
resource "google_bigquery_job" "setup_rls_policies" {
  job_id   = "setup_rls_${formatdate("YYYYMMDDhhmmss", timestamp())}"
  location = var.region

  query {
    query              = <<-SQL
      CREATE OR REPLACE ROW ACCESS POLICY rls_cymbal_internal_and_ai
      ON `${var.project_id}.${google_bigquery_dataset.retail_banking.dataset_id}.${google_bigquery_table.customer_360.table_id}`
      GRANT TO (
        "user:${var.admin_user}",
        "serviceAccount:${google_service_account.genai_agent.email}"
      )
      FILTER USING (TRUE);

      CREATE OR REPLACE ROW ACCESS POLICY rls_partner_branch_0099
      ON `${var.project_id}.${google_bigquery_dataset.retail_banking.dataset_id}.${google_bigquery_table.customer_360.table_id}`
      GRANT TO (
        "serviceAccount:${google_service_account.partner_portal.email}"
      )
      FILTER USING (branch_code = '0099');
    SQL
    use_legacy_sql     = false
    create_disposition = "CREATE_NEVER"
  }

  depends_on = [google_bigquery_job.seed_customer_data]

  lifecycle {
    ignore_changes = [job_id]
  }
}
