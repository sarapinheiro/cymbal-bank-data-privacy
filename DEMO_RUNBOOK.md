# Speaker Runbook & Demo Script: Data Security and Governance for the AI Era
**Session:** S2 · Data Security & Governance in the AI Era  
**Customer:** Cymbal Bank — Core Banking Architecture & Data Governance Teams  
**Speaker:** Customer Engineer - Data & AI, Google Cloud  
**Target Environment:** GCP Project `${PROJECT_ID:-"cymbal-bank-governance"}` (`europe-west1`) | Dataset `cymbal_retail_banking`  
**Total Duration:** 90 minutes  

---

## Session Timing Overview

| Time | Duration | Segment | Key Activities |
|---|---|---|---|
| **00:00 - 00:10** | 10 min | **1. Framing & The AI Paradox** | The AI paradox: velocity vs. control, dark data risks, and the expanded blast radius of AI agents. |
| **00:10 - 00:30** | 20 min | **2. Governance Recap & Foundations (Pillars 1 & 2)** | Knowledge Catalog, Explainable Privacy Framework, continuous SDP discovery (European/Portuguese NIF & IBAN), De-identification techniques (KMS, Tink, Tokenization). |
| **00:30 - 00:50** | 20 min | **3. Live Demo 1: Autonomous Discovery & Protection Setup** | BigQuery Studio + Knowledge Catalog: Ingestion of realistic banking data, serverless SDP profiling, taxonomy creation and Policy Tags mapping with Dynamic Data Masking (DDM). |
| **00:50 - 01:05** | 15 min | **4. Architectural Deep-Dive: Runtime Zero-Trust & SecOps** | Storage-layer enforcement (DDM, CLS, RLS), Zero-Trust Matrix for AI Agents, forensic auditing (DORA), and active defense introduction. |
| **01:05 - 01:25** | 20 min | **5. Live Demo 2: Zero-Trust Runtime, Audit Trail & Live SCC Metrics** | Unified execution of identical SQL query across 3 Personas (Analyst, GenAI Agent, Partner App) $\rightarrow$ Cloud Audit Logs $\rightarrow$ **Security Command Center (SCC) Walkthrough** (HVR Scoring, Attack Path and Choke Point). |
| **01:25 - 01:30** | 5 min | **6. Culmination, DORA Compliance & Q&A** | Synthesis of digital operational resilience, continuous governance, and production roadmap. |

---

## The Core Narrative Framework: Explainable Data Privacy for the AI Era
*Grounded in the foundational whitepaper "Explainable Data Privacy with Google Cloud" updated for the 2026 AI and Knowledge Engine stack, and informed by Sensitive Data Protection Discovery:*

Governance cannot be an afterthought or a manual checkpoint. To operationalize data privacy that satisfies regulators (ECB, National Regulators, DORA) and accelerates AI adoption, Cymbal Bank must be able to continuously and provably answer three fundamental questions:

### 1. What’s in my Cloud? (Continuous Discovery & Inventory)
- **The Core Premise:** You cannot govern or protect what you don't know exists. Cloud elasticity leads to data sprawl across BigQuery datasets, Cloud Storage buckets, and databases.
- **The Modern Tooling:** **Knowledge Catalog** paired with **Sensitive Data Protection (Cloud DLP) Discovery**.
- **The Mechanism:** Automated, serverless discovery profiles data continuously at rest—without extracting data or writing fragile scan scripts. It detects high-value financial assets and European/national identifiers (`PORTUGAL_NIF`, `PORTUGAL_NIB_NUMBER`, `IBAN_CODE`, account credentials) out-of-the-box.
- **Talk Track:**
  > *"When Cymbal Bank provisions a new datamart or ingests external feeds, Knowledge Catalog and Sensitive Data Protection immediately index and fingerprint the data. We eliminate 'dark data' before it becomes a compliance liability."*

### 2. What’s it used for? (Context, Sensitivity & De-identification by Default)
- **The Core Premise:** In enterprise banking, **over 90% of analytical and AI use cases do NOT require raw PII**. Business analysts and machine learning models rarely need to see a customer's raw tax number or full IBAN; they need statistical distributions, embeddings, or surrogate keys.
- **The Mechanism:**
  - Automated profiling assigns sensitivity tiers and data risk scores.
  - De-identification via **surrogates / tokenization** and **un-identification** (replacing sensitive attributes with contextual surrogates).
  - Integration with **Cloud KMS envelope encryption (DEK/KEK)** and **Google Tink** to ensure cryptographic transformations are reversible only for authorized systems.
- **Talk Track:**
  > *"We challenge the historical default where teams request raw customer tables. By de-identifying data at the boundary and embedding masking policies, data becomes safe by design for analytics and LLM grounding."*

#### Architectural Spotlight: Automated Encryption & Pseudonymization Pipeline (DLP + KMS + Tink)
*Direct alignment with Enterprise Architecture & Data Governance requirements:*
1. **Knowledge Catalog Aspect Types (`cymbal-sensitivity-tier`)**:
   - Columns are tagged with custom Knowledge Catalog Aspect Types indicating the sensitivity tier (`tipo1`, `tipo2`, `tipo3`).
2. **Envelope Encryption with Cloud KMS (`cymbal-envelope-keyring` / `cymbal-datamart-kek`)**:
   - Uses a Keyring in Cloud KMS where a Data Encryption Key (DEK) is wrapped by a Key Encryption Key (KEK).
3. **Google Tink Cryptographic Standard**:
   - De-identification and pseudonymization algorithms are compatible with Google's Tink library, ensuring deterministic, standards-compliant, and secure cryptographic operations across environments.
4. **Cloud DLP De-identification Templates (`cymbal-tink-pseudonymization`)**:
   - Differentiated de-identification actions applied to each sensitivity category.
5. **Automated Batch Processing (Dataflow / Cloud Composer)**:
   - A scheduled job reads Knowledge Catalog aspect metadata and KMS keys to pseudonymize datamarts, writing protected datasets directly into destination BigQuery tables.
6. *Talk Track:*
   > *"This architecture bridges Knowledge Catalog's active metadata with Cloud KMS envelope encryption and Google Tink. It guarantees that Cymbal Bank's datamarts are mathematically pseudo-anonymized before downstream AI agents or analytics jobs touch them, fully honoring GDPR Art. 25/32 and banking confidentiality."*

---

## Demo 1: Simplified 3-Step Walkthrough (35–55 min)

### Pre-Demo Prep (Run 1 minute before the session)
Reset `customer_360` to the **"Before" (Raw Unprotected)** state so that when you open BigQuery Studio in Step 1, no Policy Tags are attached yet:
```bash
bash reset_demo1_unprotected.sh
```

---

### Step 1 (The Problem): Show the Raw, Unprotected Table in BigQuery
1. Open **BigQuery Studio** on table `cymbal_retail_banking.customer_360`.
2. Click the **Schema** tab and **Preview** tab of `customer_360`.
3. Point out to the audience:
   - The **Policy tags** column is completely **empty**.
   - Raw Tax Numbers (`214872912`), IBANs (`PT50009900990001234567877`), and account balances (`84,320.50 €`) are sitting in cleartext.
4. *Talk Track:* 
   > "Here is a new banking table (`customer_360`) that just landed in BigQuery. Right now, the Policy Tags column is empty—meaning any service account or AI agent with `BigQuery Data Viewer` on this dataset can read raw tax identifiers, IBANs, and customer balances."

---

### Step 2 (Pillar 1 — Discover): Show Automatic SDP Scan Results
1. Switch to Browser Tab 2: **Sensitive Data Protection Inspection Job** (`i-cymbal_customer_360_sdp_scan_01` in region `europe-west1`).
2. Point out the **Findings Summary**:
   - `PORTUGAL_NIF`: **15 findings** (`VERY_LIKELY`)
   - `IBAN_CODE`: **5 findings** (`VERY_LIKELY`)
   - `PORTUGAL_NIB_NUMBER`: **5 findings** (`VERY_LIKELY`)
   - `EMAIL_ADDRESS`: **5 findings**
3. *Talk Track:*
   > "Instead of data stewards manually auditing schemas, Sensitive Data Protection scanned this table serverless-ly (zero-copy) and immediately flagged `portugal_nif` and `iban` as High-Sensitivity banking identifiers."

---

### Step 3 (Pillar 2 — Protect): Apply Policy Tags & Dynamic Masking in 1 Click
1. Switch to Browser Tab 3: **BigQuery Policy Tag Taxonomy `Cymbal_Banking_Governance`**.
2. Expand **`Restricted_Banking_Secret`** to show the 3 pre-configured masking rules:
   - `Restricted_NIF` $\rightarrow$ **SHA-256** (`cymbal_ddm_nif_sha256`)
   - `Restricted_IBAN` $\rightarrow$ **Custom Masking `************`** (`cymbal_ddm_iban_mask`)
   - `Restricted_Balance` $\rightarrow$ **Nullify (`NULL`)** (`cymbal_ddm_balance_null`)
3. **Live Action (1-Line Command or UI):** Run this single command in your terminal (or click **Edit Schema** in BigQuery Studio):
   ```bash
   bash apply_demo1_protection.sh
   ```
4. Switch back to **BigQuery Studio** (`customer_360` **Schema** tab) and click **Refresh**:
   - Show the audience that `portugal_nif`, `iban`, and `account_balance` now display their `Cymbal_Banking_Governance` Policy Tags & Data Masking badges!
5. *Talk Track:*
   > "With one command—and zero data copies or SQL views—we attached our Policy Tags to the table. The protection is now enforced directly inside the BigQuery Storage Engine, setting the stage for Demo 2."

---

## Segment 4: Architectural Deep-Dive — Runtime Zero-Trust & SecOps (Pillar 3)

### 3. Who has (or should have) access to it? (Engine-Level Access & Continuous Audit)
- **The Core Premise:** Access is not a binary permit. Access must be contextual, attribute-based, and differentiate between **human users** and **autonomous AI agents**.
- **The Mechanism:**
  - **BigQuery Storage-Level Enforcement:** Policy Tags drive Dynamic Data Masking (DDM), Column-Level Security (CLS), and Row-Level Security (RLS). Enforced at the storage API layer—impossible to bypass via alternate SQL clients or Python SDKs.
  - **Identity Scoping for AI:** Scoping Service Accounts so LLM prompts receive masked context, eliminating prompt injection leakage risks.
  - **Cloud Audit Logs:** Answering "Who accessed what column, when, and under which policy tag?", providing tamper-proof evidence for GDPR Art. 30 and DORA Art. 12.
- **Talk Track:**
  > *"Whether a human risk analyst or a Vertex AI agent executes a query, the BigQuery engine evaluates the identity and dynamically projects either cleartext, hashed, or nullified columns—all logged in real time."*

---

## Demo 2: Step-by-Step Walkthrough (55–75 min)

### Objective
Prove least-privilege access enforcement and auditability by running the exact same SQL query across three personas.

### The Unified Query ([`03_demo2_rls_and_personas.sql`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/03_demo2_rls_and_personas.sql))
```sql
SELECT
  customer_id,
  full_name,
  portugal_nif,
  iban,
  account_balance,
  risk_segment,
  branch_code
FROM
  `cymbal-bank-governance.cymbal_retail_banking.customer_360`
ORDER BY
  customer_id ASC;
```

### Part A: Execution Across 3 Personas

#### Persona 1: Risk & Compliance Analyst (`admin@cymbalbank.altostrat.com` / `analyst@cymbalbank.com`)
- **How to execute:** Run in BigQuery Studio as your authenticated Google user (with `Fine-Grained Reader` role), or via CLI:
  ```bash
  bq query --project_id=${PROJECT_ID:-"cymbal-bank-governance"} --use_legacy_sql=false \
    "$(cat 03_demo2_rls_and_personas.sql | sed -n '31,42p')"
  ```
- **Result:**
  - 5 rows returned.
  - Full plaintext for all columns (full NIF `214872912`, complete IBAN `PT50009900990001234567877`, actual account balance `84320.50`).
- **Key Message:** Authorised compliance personnel retain full operational fidelity without workaround pipelines.

#### Persona 2: GenAI Customer Assist Agent (`sa-cymbal-genai-agent`)
- **How to execute:** Impersonate the service account in Cloud Shell or terminal (or run `./run_demo2_personas.sh`):
  ```bash
  CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT=sa-cymbal-genai-agent@${PROJECT_ID}.iam.gserviceaccount.com \
    bq query --project_id=${PROJECT_ID} --use_legacy_sql=false \
    "$(cat 03_demo2_rls_and_personas.sql | sed -n '31,42p')"
  ```
- **Result:**
  - 5 rows returned.
  - `full_name`: Plaintext (agent needs to greet the customer).
  - `portugal_nif`: SHA-256 hash (`+pZoqHvWHamrWro3ky/b9ue9ptVh5OHkXbbC844AC3Y=` Base64 / Hex `fa9668a87bd61da9ab5aba37932fdbf6e7bda6d561e4e1e45db6c2f38e000b76` — allows model to perform join/lookup operations without seeing raw tax numbers).
  - `iban`: Masked (`************`).
  - `account_balance`: `NULL` (no business need to know exact balance).
- **Key Message:** 
  > "Even if an attacker uses prompt injection or jailbreaks the LLM, the model cannot leak banking secrets because it never received them in its context window."

#### Persona 3: External Partner Application (`sa-cymbal-partner-portal`)
- **How to execute:** Impersonate the partner service account:
  ```bash
  CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT=sa-cymbal-partner-portal@${PROJECT_ID}.iam.gserviceaccount.com \
    bq query --project_id=${PROJECT_ID} --use_legacy_sql=false \
    "$(cat 03_demo2_rls_and_personas.sql | sed -n '31,42p')"
  ```
- **Result:**
  - **Only 3 rows returned** (customers with `branch_code = '0099'`).
  - Financial columns remain masked (`+pZoqHvWHamrWro3ky/b9ue9ptVh5OHkXbbC844AC3Y=` SHA-256 NIF, `************` IBAN, `NULL` balance).
- **Key Message:** Row-Level Security (RLS) dynamically filters rows based on caller attributes, while Dynamic Data Masking protects columns—zero code changes required in the query.

---

### Part B: The Immutable Audit Trail (Cloud Logging)
1. Switch to **Cloud Logging > Logs Explorer** in project `${PROJECT_ID}`.
2. Run filter:
   ```
   protoPayload.serviceName="bigquery.googleapis.com"
   AND protoPayload.resourceName=~"datasets/cymbal_retail_banking/tables/customer_360"
   ```
3. Expand the log entry:
   - Highlight `principalEmail`: clearly distinguishes between the human analyst (`admin@cymbalbank.altostrat.com`) and the AI agent service account (`sa-cymbal-genai-agent`).
   - Highlight `tableDataRead.referencedFields` and `policyTagNames`: logs exact columns requested and policy tags evaluated.
4. *Talk Track:*
   > "For GDPR Art. 30 and DORA Article 12, Cymbal Bank can prove at any moment which human or automated entity touched banking secrets, down to the exact column and timestamp."

---

### Part C: Live Security Command Center (SCC) Walkthrough (Grand Finale)
*Bridging Data Governance directly into Enterprise Cyber Defense & CISO Operations (5–7 min)*

#### 1. Navigate to SCC Assets & High-Value Resources (HVR)
1. Open Google Cloud Console $\rightarrow$ **Security** $\rightarrow$ **Security Command Center** (or **Risk Overview / Assets**).
2. No separador **Assets**, aplicar filtro:
   - Resource Type: `bigquery.googleapis.com/Table`
   - Procurar: `cymbal_retail_banking.customer_360`
3. **O que destacar no ecrã para os Líderes de Arquitetura e Cibersegurança:**
   - **Data Sensitivity Score:** O SCC exibe automaticamente a pontuação de sensibilidade (*High / Restricted*) derivada diretamente da perfilagem do Sensitive Data Protection (SDP) executada na Demo 1.
   - **High-Value Resource (HVR) Tag:** A tabela foi classificada automaticamente como ativo de alto valor, sem necessidade de configuração manual pela equipa de cibersegurança.
4. *Talk Track:*
   > *"Reparem como a governança de dados e a cibersegurança deixam de viver em silos. O scan que executámos no SDP na Demo 1 informou instantaneamente o Security Command Center de que este dataset contém identificadores e segredos bancários, elevando a tabela ao estatuto de High-Value Resource."*

#### 2. Risk Engine & Attack Path Simulation
1. No menu lateral do SCC, clicar em **Vulnerabilities** $\rightarrow$ **Attack Paths** (ou **Risk Engine Simulation**).
2. Selecionar o recurso alvo: `customer_360`.
3. **O que destacar no ecrã:**
   - O grafo de simulação mostra como um vetor perimetral (ex: uma VM exposta ou uma Service Account externa comprometida) pode movimentar-se lateralmente até alcançar a tabela BigQuery.
   - O SCC calcula o risco combinando a sensibilidade dos dados com a probabilidade de exploração (*Toxic Combinations*).
4. *Talk Track:*
   > *"O SCC não olha apenas para 'vulnerabilidades soltas'. O Risk Engine simula exatamente o grafo de ataque que um adversário percorreria para chegar aos depósitos e identificadores do Cymbal Bank. Como sabemos exatamente onde estão os dados críticos, o SOC prioriza apenas o que tem impacto real no negócio."*

#### 3. Choke Point Remediation (Corte do Caminho de Ataque)
1. Clicar no ponto de estrangulamento sugerido pelo SCC (**Choke Point**).
2. Mostrar a recomendação prescritiva:
   - Exemplo: revogar uma permissão IAM excessiva ou reforçar o perímetro de **VPC Service Controls**.
   - Mostrar como a aplicação dessa única remediação neutraliza múltiplos caminhos de ataque em simultâneo.
3. *Talk Track:*
   > *"Com uma única ação de remediação recomendada pelo SCC, quebramos o caminho de exfiltração antes que qualquer agente malicioso consiga tocar nos dados. É a convergência perfeita entre Governança de Dados e Ciberdefesa (DORA Art. 9/12)."*

---

## Segment 6: Culmination, Regulatory Mapping & Production Roadmap (01:25–01:30)

| Regulation / Standard | Mandate | Google Cloud Native Implementation |
|---|---|---|
| **GDPR Art. 25 (Privacy by Design)** | Systemic pseudonymization and data minimization by default. | Automated DLP scanning + BigQuery Dynamic Data Masking at storage layer. |
| **GDPR Art. 32 (Security of Processing)** | Confidentiality, integrity, availability, and resilience of processing systems. | Engine-level Column-Level Security (CLS), Customer Managed Encryption Keys (CMEK), Assured Workloads EU boundaries. |
| **DORA (EU 2022/2554) Art. 9** | ICT Risk Management: Protection against unauthorized access, corruption, or data exfiltration. | Scoped Service Accounts for AI agents; prevention of sensitive data ingestion into model prompt contexts. |
| **DORA Art. 12** | Continuous digital operational resilience and immutable audit logging. | Cloud Audit Logs (`DataRead` / `DataWrite`) retained with tamper-proof log buckets. |
| **Cymbal Bank 4-Tier Matrix** | `Confidencial`, `Restrito`, `Interno`, `Público` data classification. | 1:1 Knowledge Catalog Taxonomy hierarchy mapping directly to enterprise data policies and Concierge Change Workflows. |
