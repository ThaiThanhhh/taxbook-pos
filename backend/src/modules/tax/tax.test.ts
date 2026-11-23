import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { calculateTax } from './tax-engine';
import { loadParams, selectParams, TaxParams, validateParams } from './tax-params';

async function draft(): Promise<TaxParams> {
  return validateParams(JSON.parse(await readFile(resolve('../config/tax/tax-params.v0.json'), 'utf8')));
}
test('demo arithmetic: goods and services with explicitly supplied bases', async () => {
  const params = await draft();
  const goods = calculateTax(params, [{ sector_code: 'GOODS_DISTRIBUTION', vat_base_vnd: 200000000, pit_base_vnd: 200000000 }], { mode: 'DEMO', rounding: 'HALF_UP' });
  assert.equal(goods.vat_vnd, 2000000);
  assert.equal(goods.pit_vnd, 1000000);
  assert.equal(goods.status, 'DRAFT_UNVERIFIED');
  const services = calculateTax(params, [{ sector_code: 'SERVICE', vat_base_vnd: 100000000, pit_base_vnd: 100000000 }], { mode: 'DEMO', rounding: 'HALF_UP' });
  assert.equal(services.vat_vnd, 5000000);
  assert.equal(services.pit_vnd, 2000000);
});
test('unapproved config cannot produce official calculations', async () => {
  const params = await draft();
  assert.throws(() => calculateTax(params, [{ sector_code: 'SERVICE', vat_base_vnd: 1, pit_base_vnd: 1 }], { mode: 'OFFICIAL', rounding: 'HALF_UP' }), /Unverified/);
  assert.equal(selectParams([params], '2026-10-31'), undefined);
});
test('rounding uses exact decimal rates, rejects bad bases and duplicate sectors', async () => {
  const params = await draft();
  const bases = [{ sector_code: 'GOODS_DISTRIBUTION', vat_base_vnd: 50, pit_base_vnd: 100 }];
  assert.equal(calculateTax(params, bases, { mode: 'DEMO', rounding: 'HALF_UP' }).vat_vnd, 1);
  assert.equal(calculateTax(params, bases, { mode: 'DEMO', rounding: 'FLOOR' }).vat_vnd, 0);
  assert.throws(() => calculateTax(params, [{ ...bases[0], vat_base_vnd: -1 }], { mode: 'DEMO', rounding: 'FLOOR' }));
  assert.throws(() => calculateTax(params, [bases[0], bases[0]], { mode: 'DEMO', rounding: 'FLOOR' }));
  params.rates.GOODS_DISTRIBUTION.vat = 1e-7;
  assert.equal(calculateTax(params, [{ ...bases[0], vat_base_vnd: 10000000 }], { mode: 'DEMO', rounding: 'FLOOR' }).vat_vnd, 1);
});
test('approved effective dates include both boundaries and reject missing approval metadata', async () => {
  const p: TaxParams = { ...await draft(), id: 'test-only', status: 'APPROVED', approved_by: 'test-reviewer', filing_period: 'QUARTER', effective_to: '2026-12-31' };
  validateParams(p);
  assert.equal(selectParams([p], '2026-01-01')?.version, p.version);
  assert.equal(selectParams([p], '2026-12-31')?.version, p.version);
  assert.equal(selectParams([p], '2027-01-01'), undefined);
  assert.throws(() => validateParams({ ...p, approved_by: '' }));
  assert.throws(() => validateParams({ ...p, effective_from: '2026-02-30' }));
});
test('loader rejects duplicate versions and overlapping approved effective ranges', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'taxbook-params-'));
  try {
    const p: TaxParams = { ...await draft(), id: 'test-only', status: 'APPROVED', approved_by: 'test-reviewer', filing_period: 'QUARTER' };
    await writeFile(join(dir, 'tax-params.a.json'), JSON.stringify(p));
    await writeFile(join(dir, 'tax-params.b.json'), JSON.stringify(p));
    await assert.rejects(() => loadParams(dir), /Duplicate/);
    await writeFile(join(dir, 'tax-params.b.json'), JSON.stringify({ ...p, version: 'test-next', effective_from: '2027-01-01' }));
    await assert.rejects(() => loadParams(dir), /overlap/);
  } finally { await rm(dir, { recursive: true, force: true }); }
});
