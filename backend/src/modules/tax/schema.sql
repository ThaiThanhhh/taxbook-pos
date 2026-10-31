-- Proposal only. Obtain team migration numbering from Quang Dung before shared deployment.
CREATE TABLE tax_param_set (
  id uuid PRIMARY KEY, version text NOT NULL UNIQUE, effective_from date NOT NULL,
  effective_to date, status text NOT NULL CHECK (status IN ('DRAFT_UNVERIFIED','APPROVED')),
  approved_by text, payload jsonb NOT NULL,
  CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CHECK (status <> 'APPROVED' OR length(trim(approved_by)) > 0 AND approved_by IS NOT NULL)
);
CREATE TABLE tax_period (
  id uuid PRIMARY KEY, household_id text NOT NULL, label text NOT NULL,
  start_date date NOT NULL, end_date date NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','CONFIRMED')),
  param_set_id uuid REFERENCES tax_param_set(id),
  revenue_vnd bigint, vat_vnd bigint, pit_vnd bigint, method text,
  CHECK (start_date <= end_date), UNIQUE (household_id, label),
  CHECK (status <> 'CONFIRMED' OR (param_set_id IS NOT NULL AND vat_vnd IS NOT NULL AND pit_vnd IS NOT NULL))
);
CREATE INDEX tax_period_household_idx ON tax_period (household_id, start_date, end_date);
