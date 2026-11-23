#!/usr/bin/env bash
# ==============================================================================
# Cymbal Bank - Data Security & Governance for the AI Era
# Script 02: Knowledge Catalog Taxonomy, Policy Tags, DDM, SDP, Aspects & KMS
# Target Project: ${PROJECT_ID:-"cymbal-bank-governance"} | Region: europe-west1
# ==============================================================================
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-"cymbal-bank-governance"}"
LOCATION="${LOCATION:-"europe-west1"}"
DATASET_ID="${DATASET_ID:-"cymbal_retail_banking"}"
TABLE_ID="${TABLE_ID:-"customer_360"}"
ADMIN_USER="${ADMIN_USER:-"admin@cymbalbank.altostrat.com"}"
ANALYST_USER="user:${ADMIN_USER}"
GENAI_SA="serviceAccount:sa-cymbal-genai-agent@${PROJECT_ID}.iam.gserviceaccount.com"
PARTNER_SA="serviceAccount:sa-cymbal-partner-portal@${PROJECT_ID}.iam.gserviceaccount.com"

TOKEN=$(CLOUDSDK_METRICS_ENVIRONMENT="${CLOUDSDK_METRICS_ENVIRONMENT:+$CLOUDSDK_METRICS_ENVIRONMENT }datacloud.antigravity" gcloud auth application-default print-access-token)

echo "=== 1. Creating Knowledge Catalog Taxonomy (Cymbal_Banking_Governance) ==="
python3 - <<PYEOF
import json, ssl, urllib.request, urllib.error, subprocess

ssl_ctx = ssl._create_unverified_context()
project_id = "${PROJECT_ID}"
location = "${LOCATION}"
token = "${TOKEN}"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
    "x-goog-user-project": project_id,
}

def api_call(method, url, body=None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=ssl_ctx) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err_text = e.read().decode("utf-8")
        print(f"HTTP {e.code} on {method} {url}: {err_text}")
        raise

# 1. Check or create Taxonomy 'Cymbal_Banking_Governance'
tax_url = f"https://datacatalog.googleapis.com/v1/projects/{project_id}/locations/{location}/taxonomies"
existing = api_call("GET", tax_url).get("taxonomies", [])
taxonomy = next((t for t in existing if t.get("displayName") == "Cymbal_Banking_Governance"), None)
if not taxonomy:
    taxonomy = api_call("POST", tax_url, {
        "displayName": "Cymbal_Banking_Governance",
        "description": "Cymbal Bank 4-Tier Enterprise Data Classification Matrix (Confidencial, Restrito, Interno, Público)",
        "activatedPolicyTypes": ["FINE_GRAINED_ACCESS_CONTROL"]
    })
    print("Created Taxonomy:", taxonomy["name"])
else:
    print("Found existing Taxonomy:", taxonomy["name"])

tax_name = taxonomy["name"]

# 2. Check or create Policy Tags
pt_url = f"https://datacatalog.googleapis.com/v1/{tax_name}/policyTags"
existing_pts = api_call("GET", pt_url).get("policyTags", [])
pt_by_name = {p["displayName"]: p for p in existing_pts}

def ensure_pt(display_name, desc, parent=None):
    if display_name in pt_by_name:
        return pt_by_name[display_name]["name"]
    body = {"displayName": display_name, "description": desc}
    if parent:
        body["parentPolicyTag"] = parent
    created = api_call("POST", pt_url, body)
    pt_by_name[display_name] = created
    print(f"Created Policy Tag {display_name}: {created['name']}")
    return created["name"]

# Cymbal Bank 4 Tiers + child tags for granular DDM rules
ensure_pt("Confidential_PII", "Tier 1 (Confidencial): Sensitive PII & GDPR Protected Data")
parent_restricted = ensure_pt("Restricted_Banking_Secret", "Tier 2 (Restrito): Banking Secrecy and Critical Identifiers")
ensure_pt("Interno_Operational", "Tier 3 (Interno): Internal Operational Banking Data")
ensure_pt("Publico_Open", "Tier 4 (Público): Public Data")

pt_nif = ensure_pt("Restricted_NIF", "Tax Identification Number (DDM Rule: SHA-256 Hash)", parent_restricted)
pt_iban = ensure_pt("Restricted_IBAN", "Deposit IBAN (DDM Rule: String Masking ************)", parent_restricted)
pt_balance = ensure_pt("Restricted_Balance", "Account Balance EUR (DDM Rule: NULLIFY)", parent_restricted)

# 3. Grant Fine-Grained Reader on Policy Tags to Persona 1 (Analyst)
for pt in [parent_restricted, pt_nif, pt_iban, pt_balance]:
    api_call("POST", f"https://datacatalog.googleapis.com/v1/{pt}:setIamPolicy", {
        "policy": {
            "bindings": [{
                "role": "roles/datacatalog.categoryFineGrainedReader",
                "members": [
                    "${ANALYST_USER}"
                ]
            }]
        }
    })
print("Granted Fine-Grained Reader on Policy Tags to ${ANALYST_USER}")

# 4. Create BigQuery Data Policies (DDM) in target region
dp_url = f"https://bigquerydatapolicy.googleapis.com/v1/projects/{project_id}/locations/{location}/dataPolicies"
existing_dps = api_call("GET", dp_url).get("dataPolicies", [])
dp_by_id = {d.get("dataPolicyId"): d for d in existing_dps}

def ensure_dp(dp_id, policy_tag, predefined_expr=None, routine=None):
    mask_policy = {"predefinedExpression": predefined_expr} if predefined_expr else {"routine": routine}
    body = {
        "dataPolicyId": dp_id,
        "dataPolicyType": "DATA_MASKING_POLICY",
        "policyTag": policy_tag,
        "dataMaskingPolicy": mask_policy
    }
    if dp_id in dp_by_id:
        dp_name = dp_by_id[dp_id]["name"]
        print(f"Found existing Data Policy {dp_id}: {dp_name}")
    else:
        created = api_call("POST", dp_url, body)
        dp_name = created["name"]
        print(f"Created Data Policy {dp_id}: {dp_name}")
    # Grant Masked Reader to Persona 2 (GenAI Agent) and Persona 3 (Partner App)
    api_call("POST", f"https://bigquerydatapolicy.googleapis.com/v1/{dp_name}:setIamPolicy", {
        "policy": {
            "bindings": [{
                "role": "roles/bigquerydatapolicy.maskedReader",
                "members": ["${GENAI_SA}", "${PARTNER_SA}"]
            }]
        }
    })
    return dp_name

ensure_dp("cymbal_ddm_nif_sha256", pt_nif, predefined_expr="SHA256")
ensure_dp("cymbal_ddm_iban_mask", pt_iban, routine=f"projects/{project_id}/datasets/${DATASET_ID}/routines/mask_iban_stars")
ensure_dp("cymbal_ddm_balance_null", pt_balance, predefined_expr="ALWAYS_NULL")

# 5. Save Policy Tag resource names to a schema JSON to attach to customer_360
schema = [
    {"name": "customer_id", "type": "STRING", "mode": "NULLABLE", "description": "Unique Customer Identifier at Cymbal Bank"},
    {"name": "full_name", "type": "STRING", "mode": "NULLABLE", "description": "Customer Full Legal Name"},
    {"name": "portugal_nif", "type": "STRING", "mode": "NULLABLE", "description": "Portuguese Tax Identification Number (NIF - Mod 11 validated)", "policyTags": {"names": [pt_nif]}},
    {"name": "iban", "type": "STRING", "mode": "NULLABLE", "description": "Bank Account IBAN (Cymbal Bank 0099 - Mod 97 validated)", "policyTags": {"names": [pt_iban]}},
    {"name": "email", "type": "STRING", "mode": "NULLABLE", "description": "Customer Primary Email Address"},
    {"name": "account_balance", "type": "NUMERIC", "mode": "NULLABLE", "description": "Current Account Balance in EUR", "policyTags": {"names": [pt_balance]}},
    {"name": "risk_segment", "type": "STRING", "mode": "NULLABLE", "description": "Internal Credit & Compliance Risk Segment"},
    {"name": "branch_code", "type": "STRING", "mode": "NULLABLE", "description": "Cymbal Bank Home Branch Code (Agência)"}
]
with open("/tmp/cymbal_customer_360_schema.json", "w") as f:
    json.dump(schema, f, indent=2)
print("Wrote /tmp/cymbal_customer_360_schema.json")
PYEOF

echo "=== 2. Applying Policy Tags to BigQuery Table customer_360 ==="
bq update --project_id="${PROJECT_ID}" --set_label datacloud:antigravity \
  "${PROJECT_ID}:${DATASET_ID}.${TABLE_ID}" /tmp/cymbal_customer_360_schema.json

echo "=== 3. Creating Cloud KMS Keyring & Key (Cymbal Architectural Spotlight) ==="
CLOUDSDK_METRICS_ENVIRONMENT="${CLOUDSDK_METRICS_ENVIRONMENT:+$CLOUDSDK_METRICS_ENVIRONMENT }datacloud.antigravity" gcloud kms keyrings create cymbal-envelope-keyring \
  --location="${LOCATION}" --project="${PROJECT_ID}" 2>/dev/null || true
CLOUDSDK_METRICS_ENVIRONMENT="${CLOUDSDK_METRICS_ENVIRONMENT:+$CLOUDSDK_METRICS_ENVIRONMENT }datacloud.antigravity" gcloud kms keys create cymbal-datamart-kek \
  --keyring=cymbal-envelope-keyring --location="${LOCATION}" \
  --purpose=encryption --project="${PROJECT_ID}" 2>/dev/null || true

echo "=== 4. Creating Knowledge Catalog Aspect Type & SDP Templates ==="
python3 - <<PYEOF
import json, ssl, urllib.request, urllib.error

ssl_ctx = ssl._create_unverified_context()
project_id = "${PROJECT_ID}"
location = "${LOCATION}"
token = "${TOKEN}"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
    "x-goog-user-project": project_id,
}

def api_call(method, url, body=None, ignore_conflict=True):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, context=ssl_ctx) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err_text = e.read().decode("utf-8")
        if ignore_conflict and (e.code == 409 or "already in use" in err_text or "ALREADY_EXISTS" in err_text):
            print(f"Already exists ({e.code}): {url}")
            return {}
        print(f"HTTP {e.code} on {method} {url}: {err_text}")
        raise

# A. Create Knowledge Catalog Aspect Type 'cymbal-sensitivity-tier' (tipo1, tipo2, tipo3)
aspect_url = f"https://dataplex.googleapis.com/v1/projects/{project_id}/locations/{location}/aspectTypes?aspectTypeId=cymbal-sensitivity-tier"
api_call("POST", aspect_url, {
    "displayName": "Cymbal Bank Sensitivity Tier (Pseudonymization Pipeline)",
    "description": "Sensitivity tier classification for DLP + KMS + Tink pseudonymization pipeline (tipo1, tipo2, tipo3)",
    "metadataTemplate": {
        "name": "cymbal_sensitivity_tier",
        "type": "record",
        "recordFields": [
            {
                "name": "sensitivity_tier",
                "type": "enum",
                "index": 1,
                "annotations": {"displayName": "Sensitivity Tier (Tipo)"},
                "enumValues": [
                    {"name": "tipo1", "index": 1},
                    {"name": "tipo2", "index": 2},
                    {"name": "tipo3", "index": 3}
                ],
                "constraints": {"required": True}
            },
            {
                "name": "encryption_standard",
                "type": "string",
                "index": 2,
                "annotations": {"displayName": "Cryptographic Standard (KMS/Tink)"}
            }
        ]
    }
})
print("Ensured Knowledge Catalog Aspect Type: cymbal-sensitivity-tier")

# B. Create SDP Inspection Template 'cymbal-banking-inspection'
insp_url = f"https://dlp.googleapis.com/v2/projects/{project_id}/locations/{location}/inspectTemplates"
api_call("POST", insp_url, {
    "templateId": "cymbal-banking-inspection",
    "inspectTemplate": {
        "displayName": "Banking Inspection Template (Cymbal Bank)",
        "description": "Detects PORTUGAL_NIF, PORTUGAL_NIB_NUMBER, IBAN_CODE, EMAIL_ADDRESS, and CREDIT_CARD_NUMBER",
        "inspectConfig": {
            "infoTypes": [
                {"name": "IBAN_CODE"},
                {"name": "PORTUGAL_NIB_NUMBER"},
                {"name": "PORTUGAL_CDC_NUMBER"},
                {"name": "EMAIL_ADDRESS"},
                {"name": "CREDIT_CARD_NUMBER"}
            ],
            "customInfoTypes": [
                {
                    "infoType": {"name": "PORTUGAL_NIF"},
                    "regex": {"pattern": "[1-35-9][0-9]{8}"},
                    "likelihood": "VERY_LIKELY"
                }
            ],
            "minLikelihood": "POSSIBLE",
            "includeQuote": True
        }
    }
})
print("Ensured SDP Inspection Template: cymbal-banking-inspection")

# C. Create SDP De-identification Template 'cymbal-tink-pseudonymization'
deid_url = f"https://dlp.googleapis.com/v2/projects/{project_id}/locations/{location}/deidentifyTemplates"
api_call("POST", deid_url, {
    "templateId": "cymbal-tink-pseudonymization",
    "deidentifyTemplate": {
        "displayName": "Cymbal Bank Envelope Encryption & Pseudonymization Template",
        "description": "Differentiated de-identification rules aligned with Cymbal Bank Knowledge Catalog Aspect Types",
        "deidentifyConfig": {
            "infoTypeTransformations": {
                "transformations": [
                    {
                        "infoTypes": [{"name": "PORTUGAL_NIF"}, {"name": "PORTUGAL_NIB_NUMBER"}],
                        "primitiveTransformation": {
                            "replaceWithInfoTypeConfig": {}
                        }
                    },
                    {
                        "infoTypes": [{"name": "IBAN_CODE"}],
                        "primitiveTransformation": {
                            "characterMaskConfig": {
                                "maskingCharacter": "*",
                                "numberToMask": 21,
                                "reverseOrder": True
                            }
                        }
                    }
                ]
            }
        }
    }
})
print("Ensured SDP De-identification Template: cymbal-tink-pseudonymization")

# D. Trigger an immediate SDP Inspection Job on customer_360 & publish findings to SCC / Data Catalog
job_url = f"https://dlp.googleapis.com/v2/projects/{project_id}/locations/{location}/dlpJobs"
job_resp = api_call("POST", job_url, {
    "jobId": "cymbal_customer_360_sdp_scan_01",
    "inspectJob": {
        "storageConfig": {
            "bigQueryOptions": {
                "tableReference": {
                    "projectId": project_id,
                    "datasetId": "${DATASET_ID}",
                    "tableId": "${TABLE_ID}"
                }
            }
        },
        "inspectTemplateName": f"projects/{project_id}/locations/{location}/inspectTemplates/cymbal-banking-inspection",
        "actions": [
            {"publishSummaryToCscc": {}},
            {"publishFindingsToCloudDataCatalog": {}}
        ]
    }
}, ignore_conflict=True)
print("Triggered SDP Inspection Job:", job_resp.get("name", "cymbal_customer_360_sdp_scan_01"))

# E. Create SDP Discovery Config (Data Profiling) for BigQuery in target region
disc_url = f"https://dlp.googleapis.com/v2/projects/{project_id}/locations/{location}/discoveryConfigs"
existing_discs = api_call("GET", disc_url).get("discoveryConfigs", [])
if not existing_discs:
    disc_resp = api_call("POST", disc_url, {
        "configId": "cymbal-bq-continuous-discovery",
        "discoveryConfig": {
            "displayName": "Cymbal Bank Continuous BigQuery Discovery & Profiling",
            "status": "RUNNING",
            "inspectTemplates": [
                f"projects/{project_id}/locations/{location}/inspectTemplates/cymbal-banking-inspection"
            ],
            "targets": [
                {
                    "bigQueryTarget": {
                        "filter": {
                            "otherTables": {}
                        },
                        "cadence": {
                            "schemaModifiedCadence": {
                                "types": ["SCHEMA_NEW_COLUMNS"],
                                "frequency": "UPDATE_FREQUENCY_DAILY"
                            }
                        }
                    }
                }
            ],
            "actions": [
                {"publishToDataplexCatalog": {}}
            ]
        }
    }, ignore_conflict=True)
    print("Created SDP Discovery Config:", disc_resp.get("name", "cymbal-bq-continuous-discovery"))
else:
    print("Found existing SDP Discovery Config:", existing_discs[0].get("name"))

# F. Attach 'cymbal-sensitivity-tier' (tipo1) aspect to customer_360 Dataplex Catalog Entry
entry_name = f"projects/{project_id}/locations/{location}/entryGroups/@bigquery/entries/bigquery.googleapis.com/projects/{project_id}/datasets/${DATASET_ID}/tables/${TABLE_ID}"
aspect_key = f"{project_id}.{location}.cymbal-sensitivity-tier"
try:
    api_call("PATCH", f"https://dataplex.googleapis.com/v1/{entry_name}?updateMask=aspects", {
        "name": entry_name,
        "aspects": {
            aspect_key: {
                "aspectType": f"projects/{project_id}/locations/{location}/aspectTypes/cymbal-sensitivity-tier",
                "data": {
                    "sensitivity_tier": "tipo1",
                    "encryption_standard": "AES-256-GCM Envelope Encryption (Cloud KMS + Tink)"
                }
            }
        }
    })
    print("Attached Knowledge Catalog Aspect 'cymbal-sensitivity-tier' (tipo1) to customer_360 entry")
except Exception as ex:
    print("Note on aspect attachment:", ex)

# G. Verify SDP Inspection Job Findings
job_status = api_call("GET", f"https://dlp.googleapis.com/v2/projects/{project_id}/locations/{location}/dlpJobs/i-cymbal_customer_360_sdp_scan_01")
state = job_status.get("state", "UNKNOWN")
stats = job_status.get("inspectDetails", {}).get("result", {}).get("infoTypeStats", [])
print(f"SDP Job State: {state} | Findings: {json.dumps(stats)}")
PYEOF

echo "=== Done! ==="
