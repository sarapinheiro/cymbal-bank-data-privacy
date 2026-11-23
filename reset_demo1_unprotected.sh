#!/usr/bin/env bash
# ==============================================================================
# Cymbal Bank Demo 1: Reset customer_360 to RAW UNPROTECTED State (No Policy Tags)
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-"cymbal-bank-governance"}"
DATASET_ID="${DATASET_ID:-"cymbal_retail_banking"}"
TABLE_ID="${TABLE_ID:-"customer_360"}"

cat << 'EOF' > /tmp/cymbal_customer_360_unprotected_schema.json
[
  {"name": "customer_id", "type": "INTEGER", "mode": "NULLABLE", "description": "Unique internal customer identifier"},
  {"name": "full_name", "type": "STRING", "mode": "NULLABLE", "description": "Customer full legal name"},
  {"name": "portugal_nif", "type": "STRING", "mode": "NULLABLE", "description": "Portuguese Tax Identification Number (NIF)"},
  {"name": "iban", "type": "STRING", "mode": "NULLABLE", "description": "Customer primary deposit IBAN (PT500099...)"},
  {"name": "account_balance", "type": "NUMERIC", "mode": "NULLABLE", "description": "Aggregated checking & savings balance in EUR"},
  {"name": "risk_segment", "type": "STRING", "mode": "NULLABLE", "description": "Internal AML/Credit risk score category"},
  {"name": "branch_code", "type": "STRING", "mode": "NULLABLE", "description": "Home branch identifier (e.g. 0099 for Central Headquarters)"},
  {"name": "email", "type": "STRING", "mode": "NULLABLE", "description": "Registered customer contact email"}
]
EOF

echo "=== Stripping Policy Tags from ${DATASET_ID}.${TABLE_ID} ==="
bq update --project_id="${PROJECT_ID}" --set_label datacloud:antigravity \
  "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" /tmp/cymbal_customer_360_unprotected_schema.json

echo "=== SUCCESS! customer_360 is now RAW and UNPROTECTED for Demo 1! ==="
