-- ==============================================================================
-- Cymbal Bank - Autonomous Data Security & Governance Demo
-- File: 01_demo1_data_setup_and_dlp.sql
-- Description: Creates the retail banking dataset and seeds customer_360 table.
-- ==============================================================================

CREATE SCHEMA IF NOT EXISTS `cymbal-bank-governance.cymbal_retail_banking`
OPTIONS(
  location="europe-west1",
  description="Cymbal Bank Retail Banking Datamart - Production Mirror for Security & Governance Validation"
);

CREATE OR REPLACE TABLE `cymbal-bank-governance.cymbal_retail_banking.customer_360` (
  customer_id INT64 OPTIONS(description="Unique internal customer identifier"),
  full_name STRING OPTIONS(description="Customer full legal name"),
  portugal_nif STRING OPTIONS(description="Portuguese Tax Identification Number (NIF)"),
  iban STRING OPTIONS(description="Customer primary deposit IBAN (PT500099...)"),
  account_balance NUMERIC OPTIONS(description="Aggregated checking & savings balance in EUR"),
  risk_segment STRING OPTIONS(description="Internal AML/Credit risk score category"),
  branch_code STRING OPTIONS(description="Home branch identifier (e.g. 0099 for Central Headquarters)"),
  email STRING OPTIONS(description="Registered customer contact email")
)
OPTIONS(
  description="Cymbal Bank Customer 360 Core Banking View - High Value Asset with PII and Financial Secrets"
);

INSERT INTO `cymbal-bank-governance.cymbal_retail_banking.customer_360`
  (customer_id, full_name, portugal_nif, iban, account_balance, risk_segment, branch_code, email)
VALUES
  (1001, 'António Silva', '214872912', 'PT50009900990001234567877', 84320.50, 'LOW', '0099', 'antonio.silva@cymbal-client.com'),
  (1002, 'Maria Santos', '189234810', 'PT50009900990002345678988', 12450.80, 'MEDIUM', '0099', 'maria.santos@cymbal-client.com'),
  (1003, 'Carlos Ferreira', '258102934', 'PT50009900120003456789099', 310.20, 'HIGH', '0012', 'carlos.ferreira@cymbal-client.com'),
  (1004, 'Ana Oliveira', '201928374', 'PT50009900990004567890111', 215400.00, 'LOW', '0099', 'ana.oliveira@cymbal-client.com'),
  (1005, 'Rui Sousa', '172839401', 'PT50009900440005678901222', 45.00, 'HIGH', '0044', 'rui.sousa@cymbal-client.com');
