#!/usr/bin/env bash
# ==============================================================================
# Cymbal Bank Demo 2: Execute Unified Query Across All 3 Personas Sequentially
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-"cymbal-bank-governance"}"
DATASET_ID="${DATASET_ID:-"cymbal_retail_banking"}"
ADMIN_USER="${ADMIN_USER:-"admin@cymbalbank.altostrat.com"}"
GENAI_SA="sa-cymbal-genai-agent@${PROJECT_ID}.iam.gserviceaccount.com"
PARTNER_SA="sa-cymbal-partner-portal@${PROJECT_ID}.iam.gserviceaccount.com"

QUERY="SELECT customer_id, full_name, portugal_nif, iban, account_balance, risk_segment, branch_code FROM \`${PROJECT_ID}.${DATASET_ID}.customer_360\` ORDER BY customer_id ASC;"

echo "======================================================================"
echo "PERSONA 1: Risk & Compliance Analyst (${ADMIN_USER})"
echo "Expected: 5 rows | Full Cleartext (NIF, IBAN, Balance)"
echo "======================================================================"
bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false "${QUERY}"

echo ""
echo "======================================================================"
echo "PERSONA 2: GenAI Customer Assist Agent (${GENAI_SA})"
echo "Expected: 5 rows | Hashed NIF (SHA-256), Masked IBAN (****), NULL Balance"
echo "======================================================================"
CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="${GENAI_SA}" \
  bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false "${QUERY}"

echo ""
echo "======================================================================"
echo "PERSONA 3: External Partner Application (${PARTNER_SA})"
echo "Expected: 3 rows (Branch 0099 only) | Masked NIF, IBAN, NULL Balance"
echo "======================================================================"
CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT="${PARTNER_SA}" \
  bq query --project_id="${PROJECT_ID}" --use_legacy_sql=false "${QUERY}"

echo ""
echo "=== DEMO 2 COMPLETE: 1 Query, 3 Personas, 3 Completely Different Views! ==="
