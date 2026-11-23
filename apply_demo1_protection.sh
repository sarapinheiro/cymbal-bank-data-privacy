#!/usr/bin/env bash
# ==============================================================================
# Cymbal Bank Demo 1: Instantly Attach Policy Tags & Data Masking to customer_360
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-"cymbal-bank-governance"}"
LOCATION="${LOCATION:-"europe-west1"}"
DATASET_ID="${DATASET_ID:-"cymbal_retail_banking"}"
TABLE_ID="${TABLE_ID:-"customer_360"}"

TOKEN=$(CLOUDSDK_METRICS_ENVIRONMENT="${CLOUDSDK_METRICS_ENVIRONMENT:+$CLOUDSDK_METRICS_ENVIRONMENT }datacloud.antigravity" gcloud auth application-default print-access-token)

echo "=== Fetching Policy Tag IDs from Taxonomy Cymbal_Banking_Governance ==="
python3 - <<PYEOF
import json, ssl, urllib.request

ssl_ctx = ssl._create_unverified_context()
project_id = "${PROJECT_ID}"
location = "${LOCATION}"
token = "${TOKEN}"
headers = {"Authorization": f"Bearer {token}", "x-goog-user-project": project_id}

req = urllib.request.Request(f"https://datacatalog.googleapis.com/v1/projects/{project_id}/locations/{location}/taxonomies", headers=headers)
with urllib.request.urlopen(req, context=ssl_ctx) as resp:
    taxonomies = json.loads(resp.read().decode("utf-8")).get("taxonomies", [])

tax = next(t for t in taxonomies if t.get("displayName") == "Cymbal_Banking_Governance")
req_pts = urllib.request.Request(f"https://datacatalog.googleapis.com/v1/{tax['name']}/policyTags", headers=headers)
with urllib.request.urlopen(req_pts, context=ssl_ctx) as resp:
    pts = json.loads(resp.read().decode("utf-8")).get("policyTags", [])

pt_map = {p["displayName"]: p["name"] for p in pts}

schema = [
  {"name": "customer_id", "type": "INTEGER", "mode": "NULLABLE", "description": "Unique internal customer identifier"},
  {"name": "full_name", "type": "STRING", "mode": "NULLABLE", "description": "Customer full legal name"},
  {"name": "portugal_nif", "type": "STRING", "mode": "NULLABLE", "description": "Portuguese Tax Identification Number (NIF)", "policyTags": {"names": [pt_map["Restricted_NIF"]]}},
  {"name": "iban", "type": "STRING", "mode": "NULLABLE", "description": "Customer primary deposit IBAN (PT500099...)", "policyTags": {"names": [pt_map["Restricted_IBAN"]]}},
  {"name": "account_balance", "type": "NUMERIC", "mode": "NULLABLE", "description": "Aggregated checking & savings balance in EUR", "policyTags": {"names": [pt_map["Restricted_Balance"]]}},
  {"name": "risk_segment", "type": "STRING", "mode": "NULLABLE", "description": "Internal AML/Credit risk score category"},
  {"name": "branch_code", "type": "STRING", "mode": "NULLABLE", "description": "Home branch identifier (e.g. 0099 for Central Headquarters)"},
  {"name": "email", "type": "STRING", "mode": "NULLABLE", "description": "Registered customer contact email"}
]

with open("/tmp/cymbal_customer_360_protected_schema.json", "w") as f:
    json.dump(schema, f, indent=2)
print("Generated /tmp/cymbal_customer_360_protected_schema.json successfully.")
PYEOF

echo "=== Applying Protection Schema to ${DATASET_ID}.${TABLE_ID} ==="
bq update --project_id="${PROJECT_ID}" --set_label datacloud:antigravity \
  "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" /tmp/cymbal_customer_360_protected_schema.json

echo "=== SUCCESS! Policy Tags & Dynamic Data Masking are ACTIVE! ==="
