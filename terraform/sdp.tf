# ------------------------------------------------------------------------------
# Sensitive Data Protection (Cloud DLP) Inspection & De-identification Templates
# ------------------------------------------------------------------------------

resource "google_data_loss_prevention_inspect_template" "banking_inspection" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  template_id  = "cymbal-banking-inspection"
  display_name = "Banking Inspection Template (Cymbal Bank)"
  description  = "Detects PORTUGAL_NIF, PORTUGAL_NIB_NUMBER, IBAN_CODE, EMAIL_ADDRESS, and CREDIT_CARD_NUMBER"

  inspect_config {
    info_types {
      name = "IBAN_CODE"
    }
    info_types {
      name = "PORTUGAL_NIB_NUMBER"
    }
    info_types {
      name = "PORTUGAL_CDC_NUMBER"
    }
    info_types {
      name = "EMAIL_ADDRESS"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }

    custom_info_types {
      info_type {
        name = "PORTUGAL_NIF"
      }
      likelihood = "VERY_LIKELY"
      regex {
        pattern = "[1-35-9][0-9]{8}"
      }
    }

    min_likelihood = "POSSIBLE"
    include_quote  = true
  }

  depends_on = [google_project_service.apis]
}

resource "google_data_loss_prevention_deidentify_template" "tink_pseudonymization" {
  parent       = "projects/${var.project_id}/locations/${var.region}"
  template_id  = "cymbal-tink-pseudonymization"
  display_name = "Cymbal Bank Envelope Encryption & Pseudonymization Template"
  description  = "Differentiated de-identification rules aligned with Cymbal Bank Knowledge Catalog Aspect Types"

  deidentify_config {
    info_type_transformations {
      transformations {
        info_types {
          name = "PORTUGAL_NIF"
        }
        info_types {
          name = "PORTUGAL_NIB_NUMBER"
        }
        primitive_transformation {
          replace_with_info_type_config = true
        }
      }

      transformations {
        info_types {
          name = "IBAN_CODE"
        }
        primitive_transformation {
          character_mask_config {
            masking_character = "*"
            number_to_mask    = 21
            reverse_order     = true
          }
        }
      }
    }
  }

  depends_on = [google_project_service.apis]
}
