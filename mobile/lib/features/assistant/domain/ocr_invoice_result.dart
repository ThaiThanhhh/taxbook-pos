import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';

class OcrInvoiceResult {
  const OcrInvoiceResult({
    required this.filename,
    required this.needUserConfirmation,
    this.taxCode,
    this.invoiceDate,
    this.totalAmount,
  });

  factory OcrInvoiceResult.fromJson(Map<String, dynamic> json) {
    final extractedData =
        json['extracted_data'] as Map<String, dynamic>? ?? const {};

    return OcrInvoiceResult(
      filename: json['filename'] as String,
      taxCode:
          (extractedData['tax_code'] ?? extractedData['seller_vat_code'])
              as String?,
      invoiceDate: extractedData['invoice_date'] as String?,
      totalAmount: (extractedData['total_amount'] as num?)?.toDouble(),
      needUserConfirmation:
          extractedData['need_user_confirmation'] as bool? ?? false,
    );
  }

  final String filename;
  final String? taxCode;
  final String? invoiceDate;
  final double? totalAmount;
  final bool needUserConfirmation;

  LedgerEntry toLedgerEntry({required String category, String? customNote}) {
    final amount = totalAmount;
    if (amount == null) {
      throw StateError('Không thể tạo bút toán khi chưa có tổng tiền hóa đơn.');
    }

    final noteParts = [taxCode, customNote]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return LedgerEntry(
      id: 'ocr-${DateTime.now().microsecondsSinceEpoch}',
      book: 'EXPENSE',
      entryDate: _toEntryDate(),
      type: 'EXPENSE',
      amountVnd: amount.toInt(),
      refType: 'EXPENSE',
      category: category,
      note: noteParts.isEmpty ? null : noteParts.join(' • '),
    );
  }

  String _toEntryDate() {
    final date = invoiceDate;
    if (date == null) {
      return _formatDate(DateTime.now());
    }

    final parts = date.split('/');
    if (parts.length != 3) {
      throw FormatException('Ngày hóa đơn phải có định dạng DD/MM/YYYY.', date);
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      throw FormatException('Ngày hóa đơn không hợp lệ.', date);
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('Ngày hóa đơn không hợp lệ.', date);
    }
    return _formatDate(parsed);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
