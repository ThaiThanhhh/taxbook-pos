import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LedgerEntry', () {
    test('chi phí lưu dương, hiển thị âm', () {
      final entry = LedgerEntry.fromJson(const {
        'id': 'entry-1',
        'book': 'EXPENSE',
        'entry_date': '2026-11-05',
        'type': 'EXPENSE',
        'amount_vnd': 150000,
        'ref_type': 'EXPENSE',
        'ref_id': 'exp-1',
        'category': 'Văn phòng phẩm',
      });
      expect(entry.amountVnd, 150000);
      expect(entry.signedAmount, -150000);
      expect(entry.isNegative, isTrue);
      expect(entry.title, 'Văn phòng phẩm');
      expect(entry.subtitle, 'Sổ chi phí');
    });

    test('dòng doanh thu: số dương, nhãn tiếng Việt, tên ngành', () {
      final entry = LedgerEntry.fromJson(const {
        'id': 'entry-2',
        'book': 'REVENUE',
        'entry_date': '2026-11-05',
        'type': 'REVENUE',
        'amount_vnd': 90000,
        'ref_type': 'SALE',
        'ref_id': 'sale-1',
        'category': 'SERVICE',
        'note': 'a3f9c1',
      });
      expect(entry.signedAmount, 90000);
      expect(entry.isNegative, isFalse);
      expect(entry.title, 'Bán hàng');
      expect(entry.subtitle, 'Sổ doanh thu • Dịch vụ');
    });

    test('dòng thanh toán tiền mặt không hiện mã kỹ thuật', () {
      final entry = LedgerEntry.fromJson(const {
        'id': 'entry-3',
        'book': 'CASH',
        'entry_date': '2026-11-05',
        'type': 'CASH',
        'amount_vnd': 90000,
        'ref_type': 'SALE_PAYMENT',
        'ref_id': 'sale-1',
      });
      expect(entry.title, 'Thanh toán đơn hàng');
      expect(entry.subtitle, 'Sổ tiền mặt');
    });

    test('hủy đơn: số âm giữ nguyên, có nhãn và lý do', () {
      final entry = LedgerEntry.fromJson(const {
        'id': 'entry-4',
        'book': 'REVENUE',
        'entry_date': '2026-11-05',
        'type': 'REVENUE',
        'amount_vnd': -90000,
        'ref_type': 'SALE_REVERSAL',
        'ref_id': 'entry-2',
        'category': 'SERVICE',
        'note': 'Khách trả hàng',
      });
      expect(entry.isReversal, isTrue);
      expect(entry.signedAmount, -90000);
      expect(entry.isNegative, isTrue);
      expect(entry.title, 'Hủy đơn');
      expect(entry.subtitle, 'Sổ doanh thu • Lý do: Khách trả hàng');
    });

    test('thiếu ref_type, ref_id, category, note vẫn đọc được', () {
      final entry = LedgerEntry.fromJson(const {
        'id': 'entry-5',
        'book': 'BANK',
        'entry_date': '2026-11-05',
        'type': 'BANK',
        'amount_vnd': 500000,
      });
      expect(entry.refType, isNull);
      expect(entry.isReversal, isFalse);
      expect(entry.title, 'Sổ ngân hàng');
    });
  });
}
