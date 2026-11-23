# Guia de Estrutura das Demonstrações Técnicas (Demo Structure)
## Sessão: S2 · Segurança e Governança de Dados na Era da IA
**Cliente:** Cymbal Bank — Core Banking Architecture & Data Governance Teams  
**Apresentador(a):** Customer Engineer - Data & AI, Google Cloud  
**Ambiente de Execução:** GCP Project `${PROJECT_ID:-"cymbal-bank-governance"}` (`europe-west1`) | BigQuery Dataset `cymbal_retail_banking`

---

## Visão Geral das Demonstrações

As duas demonstrações foram desenhadas para responder de forma prática à framework **"Explainable Data Privacy"** e provar a eficácia dos controlos de segurança em tempo de execução sem afetar a agilidade analítica ou os agentes de IA.

```
+---------------------------------------------------------------------------------------------------+
|                                  FRAMEWORK EXPLAINABLE DATA PRIVACY                               |
+------------------------------------+--------------------------------+-----------------------------+
| 1. O que está na minha cloud?       | 2. Para que está a ser usado?   | 3. Quem tem acesso a isso?  |
| -> Descoberta Contínua com SDP     | -> Desidentificação por omissão | -> BigQuery DDM, CLS, RLS   |
| -> Identificadores Bancários (NIF) | -> Encriptação Envelope & Tink | -> Identidade Agente vs Hum.|
+------------------------------------+--------------------------------+-----------------------------+
                                       |                                             |
                                       v                                             v
                       +-------------------------------+             +-------------------------------+
                       |   DEMO 1: DESCOBERTA & DDM    |             |  DEMO 2: 1 QUERY, 3 PERSONAS  |
                       |  - Perfilagem automática      |             |  - Analista de Risco (Limpo)  |
                       |  - Classificação NIF / IBAN   |             |  - Agente IA (Mascarado/Hash) |
                       |  - Policy Tags & DDM          |             |  - App Parceiro (RLS Agência) |
                       +-------------------------------+             +-------------------------------+
                                                                                     |
                                                                                     v
                                                                     +-------------------------------+
                                                                     |   AUDITORIA & CULMINAÇÃO SCC  |
                                                                     |  - Cloud Audit Logs (DORA/RGPD)|
                                                                     |  - HVR Scoring no SCC         |
                                                                     |  - Simulação Attack Paths     |
                                                                     +-------------------------------+
```

---

## DEMO 1: Descoberta Autónoma, Classificação e Mascaramento Dinâmico (35–55 min)

### Preparação Pré-Sessão (Estado "Antes" — Sem Proteção)
Antes de iniciar a Demo 1, executar [`reset_demo1_unprotected.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/reset_demo1_unprotected.sh) para remover as Policy Tags da tabela `customer_360` e mostrar a tabela "crua" e desprotegida no Passo 1:
```bash
bash /Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/reset_demo1_unprotected.sh
```

### Passo 1 (O Problema): Tabela de Aterragem Desprotegida (`cymbal_retail_banking.customer_360`)
- **Consola:** Abrir **BigQuery Studio > `customer_360` > Separador Schema & Preview**.
- **O que mostrar:** A coluna **Policy tags** está vazia; 5 clientes bancários com NIFs válidos (`214872912`, etc.), IBANs do banco (`PT50009900990001234567877`) e saldos em euros estão expostos em texto limpo.

### Passo 2 (Pilar 1 — Descoberta): Inspeção Serverless com Sensitive Data Protection (SDP)
- **Consola:** Abrir **Sensitive Data Protection > Jobs > `i-cymbal_customer_360_sdp_scan_01`** (`europe-west1`).
- **O que mostrar:** Sem extrair dados do BigQuery (*zero-copy*), o template `cymbal-banking-inspection` detetou automaticamente nos 5 registos:
  - `PORTUGAL_NIF` (15 deteções — `VERY_LIKELY`)
  - `IBAN_CODE` (5 deteções — `VERY_LIKELY`)
  - `PORTUGAL_NIB_NUMBER` (5 deteções — `VERY_LIKELY`)
  - `EMAIL_ADDRESS` (5 deteções)

### Passo 3 (Pilar 2 — Proteção): Aplicar Policy Tags & Dynamic Data Masking em 1 Comando
- **Consola:** Mostrar a Taxonomia **`Cymbal_Banking_Governance`** (`Restricted_Banking_Secret` $\rightarrow$ `Restricted_NIF`, `Restricted_IBAN`, `Restricted_Balance`).
- **Ação ao Vivo (1 Comando):** Executar [`apply_demo1_protection.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/apply_demo1_protection.sh):
  ```bash
  bash /Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/apply_demo1_protection.sh
  ```
- **Resultado Visual no BigQuery Studio (Refresh no Schema):**
  - `portugal_nif` $\rightarrow$ `Restricted_NIF` (**SHA-256 Hash**)
  - `iban` $\rightarrow$ `Restricted_IBAN` (**Custom Mask `************`**)
  - `account_balance` $\rightarrow$ `Restricted_Balance` (**Nullify `NULL`**)

---

## DEMO 2: Uma Consulta, Três Personas e Pista de Auditoria Forense (55–75 min)

### Objetivo
Executar exatamente a **mesma query SQL** ([`03_demo2_rls_and_personas.sql`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/03_demo2_rls_and_personas.sql) / [`run_demo2_personas.sh`](file:///Users/sarapinheiro/.gemini/antigravity/scratch/cymbal_bank_data_governance_demo/run_demo2_personas.sh)) sob três identidades distintas para provar a aplicação de privilégio mínimo em tempo de execução e a imunidade a fugas de dados em modelos de IA generativa.

### A Consulta Unificada
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

### Matriz de Execução e Resultados por Persona

| Campo | Persona 1: Analista de Risco (`admin@cymbalbank.altostrat.com`) | Persona 2: Agente GenAI (`sa-cymbal-genai-agent`) | Persona 3: App Parceiro Ext. (`sa-cymbal-partner-portal`) |
|---|---|---|---|
| **Papel / Identidade** | Humano autenticado com função `Fine-Grained Reader` | Service Account do Agente Vertex AI (`Masked Reader`) | Service Account externa restrita (`Masked Reader` + RLS) |
| **Linhas Devolvidas** | **5 linhas** (todas as agências) | **5 linhas** (todas as agências) | **3 linhas** (Apenas Agência `0099` via RLS) |
| `customer_id` | `1001` | `1001` | `1001` |
| `full_name` | António Silva | António Silva (para saudação) | António Silva |
| `portugal_nif` | `214872912` (Texto Limpo) | `+pZoqHvWHamrWro3ky/b9ue9ptVh5OHkXbbC844AC3Y=` (SHA-256 Base64 / Hex `fa9668a87b...`) | `+pZoqHvWHamrWro3ky/b9ue9ptVh5OHkXbbC844AC3Y=` (SHA-256 Base64 / Hex `fa9668a87b...`) |
| `iban` | `PT50009900990001234567877` | `************` (Máscara Total) | `************` (Máscara Total) |
| `account_balance` | `84320.50` | `NULL` | `NULL` |
| `branch_code` | `0099`, `0012`, `0044` | `0099`, `0012`, `0044` | Apenas `0099` |

### Mensagens-Chave de Cada Persona:
1. **Analista Humano:** Operacionalidade total para funções regulamentadas sem fricção de tickets ou pedidos de dados em silos.
2. **Agente GenAI:** Proteção estrita contra *Prompt Injection* e *Jailbreaks*. O modelo nunca recebe NIFs ou IBANs na sua janela de contexto (*context window*), eliminando na raiz o risco de memorização ou fuga em respostas aos clientes.
3. **App Parceiro:** Demonstração de **Row-Level Security (RLS)** (`rls_partner_branch_0099`) combinada com DDM. A política filtra automaticamente o âmbito territorial/operacional na própria base de dados, sem necessidade de cláusulas `WHERE` manuais na aplicação.

---

## Validação da Pista de Auditoria Imutável (Cloud Audit Logs)

No **Cloud Logging**, a consulta demonstra conformidade instantânea com o **Artigo 12 do DORA** e o **Artigo 30 do RGPD**:
```
protoPayload.serviceName="bigquery.googleapis.com"
AND protoPayload.resourceName=~"datasets/cymbal_retail_banking/tables/customer_360"
```
- **Campos em Destaque:**
  - `principalEmail`: distingue inequivocamente acessos humanos (`admin@cymbalbank.altostrat.com`) vs. automações de IA (`sa-cymbal-genai-agent@cymbal-bank-governance.iam.gserviceaccount.com`) vs. parceiros (`sa-cymbal-partner-portal@cymbal-bank-governance.iam.gserviceaccount.com`).
  - `referencedFields`: audita as colunas exatas que foram projetadas.
  - `authorizationInfo`: comprova a validação das Policy Tags do Knowledge Catalog e o papel exercido.

---

## Culminação da Demo 2: Demonstração em Tempo Real no Security Command Center (SCC)

A demonstração não termina no BigQuery nem nos logs. O grande fecho (*grand finale*) da **Demo 2** liga a governança de dados à ciberdefesa ativa da organização (Slides 31–35):

```
+---------------------------------------------------------------------------------------------------+
|                        PONTE DA GOVERNANÇA DE DADOS À CIBERDEFESA ATIVA (SCC)                     |
+------------------------------------+--------------------------------+-----------------------------+
| 1. High-Value Resource (HVR)       | 2. Risk Engine & Attack Paths  | 3. Choke Point Remediation  |
| -> O SDP classifica NIFs / IBANs   | -> Simulação de movimento      | -> Uma única remediação     |
| -> SCC eleva tabela a High-Value   |    lateral até à tabela BQ     |    quebra múltiplos grafos  |
| -> Data Risk Score imediato        | -> Deteção de Toxic Combos     | -> Conformidade DORA provada|
+------------------------------------+--------------------------------+-----------------------------+
```

### Roteiro de Demonstração na Consola do SCC (5 a 7 minutos):

1. **Abrir a Consola do Google Cloud:**
   - Navegar para: **Security > Security Command Center** (ou **Risk Overview / Assets**).
2. **Passo 1: Ver o Ativo e a Pontuação HVR (Assets):**
   - Filtrar por Resource Type: `bigquery.googleapis.com/Table`
   - Selecionar a tabela `customer_360` no dataset `cymbal_retail_banking`.
   - **O que mostrar:**
     - A coluna **Data Sensitivity** / **Data Risk**: O SCC reflete automaticamente as descobertas da Demo 1 (`PORTUGAL_NIF`, `IBAN_CODE`).
     - A classificação de **High-Value Resource (HVR)**: O ativo é priorizado sem necessidade de inventário manual.
   - *Mensagem de Valor:* *"A governança não é estática. O que descobrimos no Knowledge Catalog e SDP alimenta diretamente a postura de segurança da organização."*
3. **Passo 2: Simulação de Caminhos de Ataque (Attack Path Simulation):**
   - Aceder a **Vulnerabilities > Attack Paths** e filtrar pelo recurso `customer_360`.
   - **O que mostrar:**
     - O grafo visual desenhado pelo Risk Engine da Google: mostra o caminho de um atacante hipotético que compromete uma máquina perimetral e tenta mover-se lateralmente até aos saldos bancários do Cymbal Bank.
     - A identificação de combinações tóxicas (*Toxic Combinations*): vulnerabilidade de rede + privilégio IAM + dados confidenciais descobertos.
4. **Passo 3: Remediação Cirúrgica no Ponto de Estrangulamento (Choke Point):**
   - Clicar na recomendação do **Choke Point**.
   - **O que mostrar:**
     - Uma única intervenção preventiva (ex: reforço de perímetro VPC Service Controls ou revogação de permissão IAM desnecessária) neutraliza o caminho de ataque antes que ocorra qualquer exfiltração.
   - *Mensagem de Valor:* *"Damos à equipa do CISO e aos arquitetos de dados exatamente o ponto de corte para proteger os dados mais sensíveis do banco, cumprindo a exigência de gestão de risco de TIC do Artigo 9 e 12 do DORA."*
