# Terraform Deployment Guide — Cymbal Bank Data Security & Governance

This Terraform module deploys the entire baseline infrastructure for the **Cymbal Bank Data Security & Governance Demo**, including BigQuery datasets, tables, routines, Knowledge Catalog taxonomies, Dynamic Data Masking (DDM) policies, Sensitive Data Protection (SDP) templates, Cloud KMS keyrings, and demo Service Accounts.

---

## Prerequisites

1. **Google Cloud SDK (`gcloud`)** installed and authenticated:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
2. **Terraform `>= 1.5.0`** installed.
3. A Google Cloud project where you have the **Project Owner** or **Editor + Security Admin** role.

---

## 1. Quickstart Deployment

```bash
cd terraform

# 1. Create your variables file
cp terraform.tfvars.example terraform.tfvars

# 2. Edit terraform.tfvars with your GCP project ID and email:
# project_id = "your-gcp-project"
# admin_user = "your-email@google.com"

# 3. Initialize Terraform
terraform init

# 4. Preview the infrastructure plan
terraform plan

# 5. Spin up the environment
terraform apply
```

---

## 2. Running the Live Demo

Once Terraform finishes, all resources are created and seeded with Portuguese retail banking test data.

To run the live demo steps from the parent directory:
```bash
cd ..

# Run Persona Execution (1 query, 3 personas)
./run_demo2_personas.sh

# Toggle table between Unprotected and Protected for live presentation:
./reset_demo1_unprotected.sh   # Resets table for Demo 1 Step 1 (cleartext)
./apply_demo1_protection.sh    # Activates policy tags live for Demo 1 Step 3
```

---

## 3. Teardown / Spin Down

When your session or testing is finished, wipe all resources with zero leftover cost:

```bash
cd terraform
terraform destroy
```
