import 'package:dt13_pos/features/tax/domain/tax_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = TaxEngine();
  final testCases = [
    (
      id: 'TC-TAX-001',
      sector: TaxSector.GOODS_DISTRIBUTION,
      revenue: 2400000000,
      expense: 2200000000,
      gtgt: 24000000,
      tncnCach1: 7000000,
      tncnLoiNhuan: 30000000,
    ),
    (
      id: 'TC-TAX-002',
      sector: TaxSector.PRODUCTION_TRANSPORT,
      revenue: 1800000000,
      expense: 1500000000,
      gtgt: 54000000,
      tncnCach1: 12000000,
      tncnLoiNhuan: 45000000,
    ),
    (
      id: 'TC-TAX-003',
      sector: TaxSector.SERVICE,
      revenue: 1200000000,
      expense: 900000000,
      gtgt: 60000000,
      tncnCach1: 4000000,
      tncnLoiNhuan: 45000000,
    ),
    (
      id: 'TC-TAX-004',
      sector: TaxSector.SERVICE,
      revenue: 1000000000,
      expense: 0,
      gtgt: 0,
      tncnCach1: 0,
      tncnLoiNhuan: 0,
    ),
    (
      id: 'TC-TAX-005',
      sector: TaxSector.SERVICE,
      revenue: 1000000001,
      expense: 900000000,
      gtgt: 50000000,
      tncnCach1: 0,
      tncnLoiNhuan: 15000000,
    ),
    (
      id: 'TC-TAX-006',
      sector: TaxSector.GOODS_DISTRIBUTION,
      revenue: 4000000000,
      expense: 3500000000,
      gtgt: 40000000,
      tncnCach1: null,
      tncnLoiNhuan: 85000000,
    ),
  ];

  for (final testCase in testCases) {
    test(testCase.id, () {
      final result = engine.calculateTax(
        sector: testCase.sector,
        annualRevenue: testCase.revenue,
        totalExpense: testCase.expense,
      );

      expect(result.gtgt, testCase.gtgt);
      expect(result.tncnCach1, testCase.tncnCach1);
      expect(result.tncnLoiNhuan, testCase.tncnLoiNhuan);
    });
  }
}
