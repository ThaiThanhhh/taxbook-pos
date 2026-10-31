import { money } from '../ledger/helpers';
import { TaxParams, validateParams } from './tax-params';

export interface TaxBases {
  sector_code: string;
  vat_base_vnd: number;
  pit_base_vnd: number;
}

// Integer rational arithmetic: no floating-point multiplication of VND amounts.
function multiply(base: number, rate: number, rounding: 'FLOOR' | 'HALF_UP'): number {
  const [mantissa, exponentText = '0'] = rate.toString().toLowerCase().split('e');
  const decimals = mantissa.split('.')[1]?.length ?? 0;
  const exponent = Number(exponentText) - decimals;
  let numerator = BigInt(mantissa.replace('.', ''));
  let denominator = 1n;
  if (exponent >= 0) numerator *= 10n ** BigInt(exponent);
  else denominator = 10n ** BigInt(-exponent);
  const product = BigInt(base) * numerator;
  return money(Number((product + (rounding === 'HALF_UP' ? denominator / 2n : 0n)) / denominator));
}

/** Arithmetic core only. Bases and rounding must come from a reviewed business policy.
 * Does not guess annual thresholds, mixed-sector allocation, or PROFIT_15 rules. */
export function calculateTax(params: TaxParams, bases: TaxBases[], options: {
  mode: 'OFFICIAL' | 'DEMO'; rounding: 'FLOOR' | 'HALF_UP';
}) {
  validateParams(params);
  if (!['OFFICIAL','DEMO'].includes(options.mode) || !['FLOOR','HALF_UP'].includes(options.rounding)) throw new Error('Explicit mode and rounding required');
  if (options.mode === 'OFFICIAL' && params.status !== 'APPROVED') throw new Error('Unverified tax parameters cannot be used officially');
  if (!params.pit_methods.includes('RATIO_REVENUE')) throw new Error('Revenue ratio PIT method not available');
  if (!bases.length || new Set(bases.map(b => b.sector_code)).size !== bases.length) throw new Error('Provide one aggregate base per sector');
  const lines = bases.map(base => {
    const rate = params.rates[base.sector_code];
    if (!rate) throw new Error('Unknown sector');
    money(base.vat_base_vnd); money(base.pit_base_vnd);
    return { sector_code: base.sector_code,
      vat_vnd: multiply(base.vat_base_vnd, rate.vat, options.rounding),
      pit_vnd: multiply(base.pit_base_vnd, rate.pit_revenue, options.rounding) };
  });
  return { param_version: params.version, status: params.status, mode: options.mode,
    method: 'RATIO_REVENUE' as const, rounding: options.rounding, lines,
    vat_vnd: money(lines.reduce((sum, line) => sum + line.vat_vnd, 0)),
    pit_vnd: money(lines.reduce((sum, line) => sum + line.pit_vnd, 0)) };
}
