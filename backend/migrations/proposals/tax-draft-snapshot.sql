-- Unnumbered forward proposal, review before deployment. Run once, inside a transaction.
-- Prerequisite: Ledger/Tax schema from PR #8. Does not alter financial rows.
ALTER TABLE ledger_household_lock ADD COLUMN ledger_revision bigint NOT NULL DEFAULT 0 CHECK (ledger_revision >= 0);
CREATE FUNCTION track_ledger_revision() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE targets text[] := '{}'; target text;
BEGIN
  IF TG_OP <> 'INSERT' THEN targets := array_append(targets, OLD.household_id); END IF;
  IF TG_OP <> 'DELETE' THEN targets := array_append(targets, NEW.household_id); END IF;
  FOR target IN SELECT DISTINCT unnest(targets) ORDER BY 1 LOOP
    INSERT INTO ledger_household_lock (household_id,ledger_revision) VALUES (target,1)
    ON CONFLICT (household_id) DO UPDATE SET ledger_revision=ledger_household_lock.ledger_revision+1;
  END LOOP;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER ledger_revision_change BEFORE INSERT OR UPDATE OR DELETE ON ledger_entry
FOR EACH ROW EXECUTE FUNCTION track_ledger_revision();
CREATE UNIQUE INDEX tax_period_household_id_key ON tax_period (household_id,id);
CREATE TABLE tax_draft_snapshot (
  id uuid PRIMARY KEY, household_id text NOT NULL REFERENCES ledger_household_lock(household_id), period_id uuid NOT NULL,
  start_date date NOT NULL, end_date date NOT NULL CHECK (end_date >= start_date),
  revenue_vnd bigint NOT NULL CHECK (revenue_vnd BETWEEN -9007199254740991 AND 9007199254740991),
  expense_vnd bigint NOT NULL CHECK (expense_vnd BETWEEN -9007199254740991 AND 9007199254740991),
  entry_count bigint NOT NULL CHECK (entry_count BETWEEN 0 AND 9007199254740991),
  schema_version integer NOT NULL CHECK (schema_version=1),
  param_set_id uuid REFERENCES tax_param_set(id), param_version text, param_status text, param_fingerprint text,
  source_revision bigint NOT NULL CHECK (source_revision >= 0),
  digest text NOT NULL CHECK (digest ~ '^[0-9a-f]{64}$'),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  status text NOT NULL DEFAULT 'DRAFT' CHECK (status='DRAFT'),
  official boolean NOT NULL DEFAULT false CHECK (official=false),
  tax_result jsonb CHECK (tax_result IS NULL),
  FOREIGN KEY (household_id,period_id) REFERENCES tax_period(household_id,id),
  UNIQUE (household_id,period_id,source_revision,digest)
);
CREATE INDEX tax_draft_snapshot_period_idx ON tax_draft_snapshot(household_id,period_id,created_at,id);
CREATE FUNCTION require_draft_snapshot_period() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE period_status text;
BEGIN
  IF TG_OP='UPDATE' AND (OLD.household_id<>NEW.household_id OR OLD.period_id<>NEW.period_id) THEN
    RAISE EXCEPTION 'Snapshot ownership cannot change' USING ERRCODE='23514';
  END IF;
  INSERT INTO ledger_household_lock (household_id) VALUES (NEW.household_id) ON CONFLICT DO NOTHING;
  PERFORM 1 FROM ledger_household_lock WHERE household_id=NEW.household_id FOR UPDATE;
  SELECT status INTO period_status FROM tax_period
    WHERE household_id=NEW.household_id AND id=NEW.period_id FOR SHARE;
  IF period_status IS NULL THEN RAISE EXCEPTION 'Snapshot period not found' USING ERRCODE='23503'; END IF;
  IF period_status <> 'DRAFT' THEN RAISE EXCEPTION 'Snapshot period is locked' USING ERRCODE='23514'; END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER draft_snapshot_period_guard BEFORE INSERT OR UPDATE ON tax_draft_snapshot
FOR EACH ROW EXECUTE FUNCTION require_draft_snapshot_period();
