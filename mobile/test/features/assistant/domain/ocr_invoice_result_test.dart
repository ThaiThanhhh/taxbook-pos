import 'package:dt13_pos/features/assistant/domain/ocr_invoice_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OcrInvoiceResult', () {
    test('đọc dữ liệu OCR và ánh xạ thành bút toán chi phí', () {
      final result = OcrInvoiceResult.fromJson({
        'filename': 'invoice.jpg',
        'extracted_data': {
          'tax_code': '0123456789',
          'invoice_date': '05/11/2026',
          'total_amount': 150000.75,
          'need_user_confirmation': true,
        },
      });

      expect(result.filename, 'invoice.jpg');
      expect(result.taxCode, '0123456789');
      expect(result.needUserConfirmation, isTrue);

      final entry = result.toLedgerEntry(
        category: 'Văn phòng phẩm',
        customNote: 'Mua giấy',
      );
      expect(entry.book, 'EXPENSE');
      expect(entry.type, 'EXPENSE');
      expect(entry.refType, 'EXPENSE');
      expect(entry.entryDate, '2026-11-05');
      expect(entry.amountVnd, 150000);
      expect(entry.category, 'Văn phòng phẩm');
      expect(entry.note, '0123456789 • Mua giấy');
    });

    test('dùng seller_vat_code và ngày hiện tại khi ngày hóa đơn null', () {
      final result = OcrInvoiceResult.fromJson({
        'filename': 'invoice.jpg',
        'extracted_data': {
          'seller_vat_code': '9876543210',
          'total_amount': 100000,
        },
      });

      final entry = result.toLedgerEntry(category: 'Khác');
      final today = DateTime.now();
      final expectedDate =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      expect(entry.entryDate, expectedDate);
      expect(entry.note, '9876543210');
    });

    test('báo lỗi khi thiếu tổng tiền', () {
      final result = OcrInvoiceResult.fromJson({
        'filename': 'invoice.jpg',
        'extracted_data': <String, dynamic>{},
      });

      expect(() => result.toLedgerEntry(category: 'Khác'), throwsStateError);
    });
  });
}
