-- After tax-draft-snapshot.sql, once in a transaction. Unnumbered proposal.
-- Existing period index covers period-filtered pages; this covers all periods of a household.
CREATE INDEX tax_draft_snapshot_household_page_idx ON tax_draft_snapshot(household_id,created_at,id);
