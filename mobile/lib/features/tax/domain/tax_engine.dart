// ignore_for_file: constant_identifier_names

enum TaxSector { GOODS_DISTRIBUTION, SERVICE, PRODUCTION_TRANSPORT, OTHER }

class TaxCalculation {
  const TaxCalculation({
    required this.annualRevenue,
    required this.totalExpense,
    required this.gtgt,
    required this.tncnCach1,
    required this.tncnLoiNhuan,
  });

  final int annualRevenue;
  final int totalExpense;
  final int gtgt;
  final int? tncnCach1;
  final int tncnLoiNhuan;
}

class TaxEngine {
  const TaxEngine();

  static const int NGUONG_1_TY = 1000000000;
  static const int NGUONG_3_TY = 3000000000;
  static const int NGUONG_50_TY = 50000000000;

  TaxCalculation calculateTax({
    required TaxSector sector,
    required int annualRevenue,
    required int totalExpense,
  }) {
    if (annualRevenue <= NGUONG_1_TY) {
      return TaxCalculation(
        annualRevenue: annualRevenue,
        totalExpense: totalExpense,
        gtgt: 0,
        tncnCach1: 0,
        tncnLoiNhuan: 0,
      );
    }

    final (gtgtRate, tncnRate) = switch (sector) {
      TaxSector.GOODS_DISTRIBUTION => (1, 0.5),
      TaxSector.SERVICE => (5, 2),
      TaxSector.PRODUCTION_TRANSPORT => (3, 1.5),
      TaxSector.OTHER => (2, 1),
    };

    final tncnRateOnProfit = annualRevenue <= NGUONG_3_TY
        ? 15
        : annualRevenue <= NGUONG_50_TY
        ? 17
        : 20;
    final taxableProfit = annualRevenue > totalExpense
        ? annualRevenue - totalExpense
        : 0;

    return TaxCalculation(
      annualRevenue: annualRevenue,
      totalExpense: totalExpense,
      gtgt: annualRevenue * gtgtRate ~/ 100,
      tncnCach1: annualRevenue <= NGUONG_3_TY
          ? ((annualRevenue - NGUONG_1_TY) * tncnRate ~/ 100)
          : null,
      tncnLoiNhuan: taxableProfit * tncnRateOnProfit ~/ 100,
    );
  }
}
