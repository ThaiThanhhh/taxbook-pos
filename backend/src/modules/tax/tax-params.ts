import { readFile, readdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { date, money } from '../ledger/helpers';

export const sectors = ['GOODS_DISTRIBUTION', 'SERVICE', 'PRODUCTION_TRANSPORT', 'OTHER'] as const;
export interface TaxParams {
  id?: string; version: string; status: 'DRAFT_UNVERIFIED' | 'APPROVED'; approved_by?: string;
  effective_from: string; effective_to?: string | null; threshold_vnd: number;
  vat_base: 'FULL_REVENUE' | 'EXCESS_OVER_THRESHOLD'; pit_methods: string[];
  rates: Record<string, { vat: number; pit_revenue: number }>;
  filing_period: string; legal_basis: string[];
}

export function validateParams(raw: unknown): TaxParams {
  if (!raw || typeof raw !== 'object') throw new Error('Tax parameters must be an object');
  const p = raw as TaxParams;
  if (!p.version?.trim() || !['DRAFT_UNVERIFIED','APPROVED'].includes(p.status)) throw new Error('Tax version and status required');
  date(p.effective_from, 'effective_from');
  if (p.effective_to != null) {
    date(p.effective_to, 'effective_to');
    if (p.effective_to < p.effective_from) throw new Error('Invalid effective range');
  }
  money(p.threshold_vnd, 'threshold_vnd');
  if (!['FULL_REVENUE', 'EXCESS_OVER_THRESHOLD'].includes(p.vat_base)) throw new Error('Unknown VAT base');
  if (!Array.isArray(p.pit_methods) || !p.pit_methods.length || p.pit_methods.some(m => !['RATIO_REVENUE','PROFIT_15'].includes(m))) {
    throw new Error('Unknown PIT method');
  }
  for (const sector of sectors) {
    const rate = p.rates?.[sector];
    if (!rate || [rate.vat, rate.pit_revenue].some(r => typeof r !== 'number' || !Number.isFinite(r) || r < 0 || r > 1)) {
      throw new Error(`Invalid rates for ${sector}`);
    }
  }
  if (!Array.isArray(p.legal_basis) || !p.legal_basis.length || p.legal_basis.some(b => typeof b !== 'string' || !b.trim())) {
    throw new Error('Legal basis required');
  }
  if (p.status === 'APPROVED' && (!p.id?.trim() || !p.approved_by?.trim() || !['MONTH','QUARTER','YEAR'].includes(p.filing_period))) {
    throw new Error('Approved parameters require id, approver and confirmed filing period');
  }
  return p;
}

export async function loadParams(directory: string): Promise<TaxParams[]> {
  const files = (await readdir(directory)).filter(file => /^tax-params.*\.json$/.test(file)).sort();
  const params = await Promise.all(files.map(async file => validateParams(JSON.parse(await readFile(resolve(directory, file), 'utf8')))));
  if (new Set(params.map(p => p.version)).size !== params.length) throw new Error('Duplicate tax parameter version');
  const approved = params.filter(p => p.status === 'APPROVED').sort((a,b) => a.effective_from.localeCompare(b.effective_from));
  for (let i = 1; i < approved.length; i++) {
    if (!approved[i-1].effective_to || approved[i-1].effective_to! >= approved[i].effective_from) {
      throw new Error('Approved tax parameter effective ranges overlap');
    }
  }
  return params;
}

export function selectParams(params: TaxParams[], asOf: string): TaxParams | undefined {
  date(asOf, 'as_of');
  const matches = params.filter(p => p.status === 'APPROVED' && p.effective_from <= asOf && (!p.effective_to || p.effective_to >= asOf));
  if (matches.length > 1) throw new Error('Ambiguous tax parameters');
  return matches[0];
}
