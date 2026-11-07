import 'package:flutter/foundation.dart';

@immutable
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.book,
    required this.entryDate,
    required this.type,
    required this.amountVnd,
    this.refType,
    this.refId,
    this.category,
    this.note,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String,
      book: json['book'] as String,
      entryDate: json['entry_date'] as String,
      type: json['type'] as String,
      amountVnd: (json['amount_vnd'] as num).toInt(),
      refType: json['ref_type'] as String?,
      refId: json['ref_id'] as String?,
      category: json['category'] as String?,
      note: json['note'] as String?,
    );
  }

  final String id;
  final String book;
  final String entryDate;
  final String type;
  final int amountVnd;
  final String? refType;
  final String? refId;
  final String? category;
  final String? note;

  bool get isExpense => type == 'EXPENSE';
  bool get isReversal => refType == 'SALE_REVERSAL';
  int get signedAmount => isExpense ? -amountVnd.abs() : amountVnd;
  bool get isNegative => signedAmount < 0;

  String get title {
    if (isReversal) return 'Hủy đơn';
    if (isExpense) return category ?? 'Chi phí';
    if (refType == 'SALE_PAYMENT') return 'Thanh toán đơn hàng';
    if (refType == 'SALE') return 'Bán hàng';
    return 'Sổ $_bookLabelName';
  }

  String get subtitle {
    final bookText = 'Sổ $_bookLabelName';
    if (isReversal) {
      final reason = note != null && note!.isNotEmpty ? ' • Lý do: $note' : '';
      return '$bookText$reason';
    }
    if (refType == 'SALE' && category != null) {
      return '$bookText • ${_sectorLabel(category!)}';
    }
    return bookText;
  }

  String get _bookLabelName {
    switch (book) {
      case 'REVENUE':
        return 'doanh thu';
      case 'EXPENSE':
        return 'chi phí';
      case 'CASH':
        return 'tiền mặt';
      case 'BANK':
        return 'ngân hàng';
      default:
        return book.toLowerCase();
    }
  }

  String _sectorLabel(String sector) {
    switch (sector) {
      case 'SERVICE':
        return 'Dịch vụ';
      case 'GOODS_DISTRIBUTION':
        return 'Phân phối hàng hóa';
      case 'PRODUCTION_TRANSPORT':
        return 'Sản xuất / Vận tải';
      default:
        return sector;
    }
  }
}
