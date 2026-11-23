# Cymbal Bank - Data Security & Governance for the AI Era

A complete, production-grade reference architecture and live demonstration of **Explainable Data Privacy**, **Autonomous Sensitive Data Protection (SDP)**, and **Runtime Zero-Trust Access Control** on Google Cloud.

---

## Architecture & Capabilities

```
+---------------------------------------------------------------------------------------------------+
|                                  FRAMEWORK EXPLAINABLE DATA PRIVACY                               |
+------------------------------------+--------------------------------+-----------------------------+
| 1. What's in my Cloud?             | 2. What's it used for?         | 3. Who has access to it?    |
| -> Continuous Discovery with SDP   | -> De-identification by default| -> BigQuery DDM, CLS, RLS   |
| -> High-Value Banking Secrets (NIF)| -> Envelope Encryption & Tink  | -> AI Agent vs Human Identity|
+------------------------------------+--------------------------------+-----------------------------+
                                       |                                             |
                                       v                                             v
                       +-------------------------------+             +-------------------------------+
                       |   DEMO 1: DISCOVERY & DDM     |             |  DEMO 2: 1 QUERY, 3 PERSONAS  |
                       |  - Serverless SDP profiling   |             |  - Compliance Analyst (Clean) |
                       |  - Knowledge Catalog taxonomy |             |  - GenAI Agent (Masked/Hash)  |
                       |  - Dynamic Data Masking (DDM) |             |  - Partner App (Branch RLS)   |
                       +-------------------------------+             +-------------------------------+
                                                                                     |
                                                                                     v
                                                                     +-------------------------------+
                                                                     |   AUDIT & SCC ACTIVE DEFENSE  |
                                                                     |  - Cloud Audit Logs (DORA/GDPR|
                                                                     |  - High-Value Resource (HVR)  |
                                                                     |  - Attack Path & Choke Points |
                                                                     +-------------------------------+
```

---

## File Manifest

| File | Type | Description |
|---|---|---|
| [`terraform/`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/terraform/) | Terraform | Complete IaC module to spin up (`apply`) and tear down (`destroy`) the entire baseline environment. |
| [`01_demo1_data_setup_and_dlp.sql`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/01_demo1_data_setup_and_dlp.sql) | SQL | Creates the `cymbal_retail_banking` dataset and seeds the `customer_360` table. |
| [`02_demo1_taxonomy_and_ddm.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/02_demo1_taxonomy_and_ddm.sh) | Shell / Python | Sets up Knowledge Catalog taxonomy, policy tags, DDM policies, SDP inspection templates, and Cloud KMS keys. |
| [`03_demo2_rls_and_personas.sql`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/03_demo2_rls_and_personas.sql) | SQL | Establishes Row-Level Security (RLS) policies and contains the unified demo query. |
| [`apply_demo1_protection.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/apply_demo1_protection.sh) | Shell | One-click command to attach policy tags and activate data masking on BigQuery storage. |
| [`reset_demo1_unprotected.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/reset_demo1_unprotected.sh) | Shell | Resets `customer_360` to cleartext state for step 1 of Demo 1. |
| [`run_demo2_personas.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/run_demo2_personas.sh) | Shell | Runs the single unified query sequentially across 3 impersonated identities. |
| [`DEMO_STRUCTURE.md`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/DEMO_STRUCTURE.md) | Markdown | Complete architectural guide, flow diagrams, and execution matrix. |
| [`DEMO_RUNBOOK.md`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/DEMO_RUNBOOK.md) | Markdown | Minute-by-minute speaker notes, console walkthroughs, and regulatory mappings (DORA, GDPR). |

---

## Quickstart

### Option A: Automated Provisioning with Terraform (Recommended)
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Set your project_id and admin_user in terraform.tfvars
terraform init
terraform apply

# When finished with testing:
terraform destroy
```

### Option B: Script-Based Provisioning
```bash
export PROJECT_ID="your-gcp-project-id"
export LOCATION="europe-west1"
export DATASET_ID="cymbal_retail_banking"
export ADMIN_USER="admin@yourdomain.com"

# 1. Seed BigQuery Data
bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false < 01_demo1_data_setup_and_dlp.sql

# 2. Provision Taxonomies, SDP & Masking Policies
./02_demo1_taxonomy_and_ddm.sh

# 3. Setup Row Access Policies
bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false < 03_demo2_rls_and_personas.sql

# 4. Run Multi-Persona Verification
./run_demo2_personas.sh
```
