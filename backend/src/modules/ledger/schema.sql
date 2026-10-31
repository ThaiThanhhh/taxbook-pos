-- Proposal owned by Hoai Bao; not a numbered team migration. Bootstrap only a fresh local DB.
CREATE TABLE ledger_household_lock (household_id text PRIMARY KEY);
CREATE TABLE ledger_idempotency (
  household_id text NOT NULL, operation text NOT NULL, key uuid NOT NULL,
  fingerprint text NOT NULL, response jsonb NOT NULL,
  PRIMARY KEY (household_id, operation, key)
);
CREATE TABLE expense (
  id uuid PRIMARY KEY, household_id text NOT NULL, date date NOT NULL,
  amount_vnd bigint NOT NULL CHECK (amount_vnd > 0 AND amount_vnd <= 9007199254740991),
  category text NOT NULL, vendor text, image_url text,
  source text NOT NULL CHECK (source IN ('MANUAL','OCR')),
  confirmed boolean NOT NULL DEFAULT false, confirmed_at timestamptz,
  CHECK (confirmed = (confirmed_at IS NOT NULL)), UNIQUE (household_id, id)
);
CREATE TABLE ledger_entry (
  id uuid PRIMARY KEY, household_id text NOT NULL, book text NOT NULL, entry_date date NOT NULL,
  type text NOT NULL CHECK (type IN ('REVENUE','EXPENSE','CASH','BANK')),
  amount_vnd bigint NOT NULL CHECK (amount_vnd BETWEEN -9007199254740991 AND 9007199254740991),
  ref_type text NOT NULL, ref_id text NOT NULL, category text, note text,
  UNIQUE (household_id, ref_type, ref_id, type), UNIQUE (household_id, id)
);
CREATE INDEX ledger_page_idx ON ledger_entry (household_id, entry_date, id);
CREATE TABLE bank_statement_line (
  id uuid PRIMARY KEY, household_id text NOT NULL, txn_date date NOT NULL,
  amount_vnd bigint NOT NULL CHECK (amount_vnd BETWEEN -9007199254740991 AND 9007199254740991),
  description text NOT NULL, import_hash text NOT NULL, row_number integer NOT NULL,
  matched_ledger_id uuid,
  FOREIGN KEY (household_id, matched_ledger_id) REFERENCES ledger_entry (household_id, id),
  UNIQUE (household_id, import_hash, row_number), UNIQUE (household_id, matched_ledger_id)
);
