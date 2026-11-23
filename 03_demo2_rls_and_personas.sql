-- ==============================================================================
-- Cymbal Bank Demo 2: Row-Level Security (RLS) and Persona Execution
-- Target: cymbal-bank-governance.cymbal_retail_banking.customer_360
-- ==============================================================================

-- 1. Create Row Access Policy for Internal Employees & GenAI Agent
-- They can view all customer rows across all branches (national view)
CREATE OR REPLACE ROW ACCESS POLICY rls_cymbal_internal_and_ai
ON `cymbal-bank-governance.cymbal_retail_banking.customer_360`
GRANT TO (
  "user:admin@cymbalbank.altostrat.com",
  "serviceAccount:sa-cymbal-genai-agent@cymbal-bank-governance.iam.gserviceaccount.com"
)
FILTER USING (TRUE);

-- 2. Create Row Access Policy for External Partner Portal
-- They can ONLY view customers assigned to their specific contracted branch (e.g. Branch '0099' Central)
CREATE OR REPLACE ROW ACCESS POLICY rls_partner_branch_0099
ON `cymbal-bank-governance.cymbal_retail_banking.customer_360`
GRANT TO (
  "serviceAccount:sa-cymbal-partner-portal@cymbal-bank-governance.iam.gserviceaccount.com"
)
FILTER USING (branch_code = '0099');

-- ==============================================================================
-- 3. THE UNIFIED DEMO QUERY
-- Run this EXACT query as each persona to demonstrate engine-level zero-trust!
-- ==============================================================================
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
