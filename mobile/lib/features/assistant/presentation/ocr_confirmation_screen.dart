import 'dart:io';
import 'dart:typed_data';

import 'package:dt13_pos/features/assistant/domain/ocr_invoice_result.dart';
import 'package:dt13_pos/features/ledger/data/ledger_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:dt13_pos/features/ledger/domain/ledger_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _expenseCategories = [
  'Văn phòng phẩm',
  'Chi phí vận hành',
  'Hàng hóa',
  'Khác',
];

class OcrConfirmationScreen extends ConsumerStatefulWidget {
  const OcrConfirmationScreen({
    required this.initialData,
    this.filePath,
    this.imageBytes,
    super.key,
  }) : assert(filePath != null || imageBytes != null),
       assert(filePath == null || imageBytes == null);

  final OcrInvoiceResult initialData;
  final String? filePath;
  final Uint8List? imageBytes;

  @override
  ConsumerState<OcrConfirmationScreen> createState() =>
      _OcrConfirmationScreenState();
}

class _OcrConfirmationScreenState extends ConsumerState<OcrConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController taxCodeController;
  late final TextEditingController invoiceDateController;
  late final TextEditingController totalAmountController;
  String? _pendingExpenseId;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(
      ocrConfirmationFormProvider(widget.initialData),
    );
    taxCodeController = TextEditingController(text: initialState.taxCode);
    invoiceDateController = TextEditingController(
      text: initialState.invoiceDate,
    );
    totalAmountController = TextEditingController(
      text: initialState.totalAmount,
    );
  }

  @override
  void dispose() {
    taxCodeController.dispose();
    invoiceDateController.dispose();
    totalAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formProvider = ocrConfirmationFormProvider(widget.initialData);
    final formState = ref.watch(formProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đối soát hóa đơn')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(flex: 4, child: _buildImagePreview()),
            Expanded(
              flex: 6,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    Text(
                      'Kiểm tra thông tin hóa đơn',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.initialData.needUserConfirmation) ...[
                      const SizedBox(height: 8),
                      const _ConfirmationNotice(),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: taxCodeController,
                      readOnly: _pendingExpenseId != null,
                      decoration: const InputDecoration(
                        labelText: 'Mã số thuế',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: ref.read(formProvider.notifier).updateTaxCode,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: invoiceDateController,
                      readOnly: _pendingExpenseId != null,
                      decoration: const InputDecoration(
                        labelText: 'Ngày hóa đơn',
                        hintText: 'DD/MM/YYYY',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                      validator: _validateInvoiceDate,
                      onChanged: ref
                          .read(formProvider.notifier)
                          .updateInvoiceDate,
                      onTap: _pickInvoiceDate,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: totalAmountController,
                      readOnly: _pendingExpenseId != null,
                      decoration: const InputDecoration(
                        labelText: 'Tổng tiền (VND)',
                        border: OutlineInputBorder(),
                        suffixText: '₫',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: _validateTotalAmount,
                      onChanged: ref
                          .read(formProvider.notifier)
                          .updateTotalAmount,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: formState.category,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục chi phí',
                        border: OutlineInputBorder(),
                      ),
                      items: _expenseCategories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: _pendingExpenseId != null
                          ? null
                          : (category) {
                              if (category != null) {
                                ref
                                    .read(formProvider.notifier)
                                    .updateCategory(category);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: formState.isSubmitting ? null : _submit,
                  child: formState.isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Xác nhận & Ghi sổ chi phí'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imagePath = widget.filePath;
    final bytes = widget.imageBytes;
    Image? image;
    if (imagePath != null) {
      image = Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Center(child: Text('Không thể tải ảnh hóa đơn')),
      );
    } else if (bytes != null) {
      image = Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Center(child: Text('Không thể tải ảnh hóa đơn')),
      );
    }

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
      child: image ?? const Center(child: Text('Không có ảnh hóa đơn')),
    );
  }

  Future<void> _pickInvoiceDate() async {
    final currentDate = _parseInvoiceDate(invoiceDateController.text);
    final now = DateTime.now();
    final initialDate = currentDate ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (selectedDate == null || !mounted) return;

    final formattedDate =
        '${selectedDate.day.toString().padLeft(2, '0')}/'
        '${selectedDate.month.toString().padLeft(2, '0')}/'
        '${selectedDate.year.toString().padLeft(4, '0')}';
    invoiceDateController.text = formattedDate;
    ref
        .read(ocrConfirmationFormProvider(widget.initialData).notifier)
        .updateInvoiceDate(formattedDate);
  }

  String? _validateInvoiceDate(String? value) {
    if (_parseInvoiceDate(value ?? '') == null) {
      return 'Nhập ngày theo định dạng DD/MM/YYYY.';
    }
    return null;
  }

  String? _validateTotalAmount(String? value) {
    final amount = _parseAmount(value ?? '');
    if (amount == null || amount <= 0) {
      return 'Nhập tổng tiền hợp lệ lớn hơn 0.';
    }
    return null;
  }

  DateTime? _parseInvoiceDate(String value) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})$',
    ).firstMatch(value.trim());
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  double? _parseAmount(String value) {
    var normalized = value.trim().replaceAll(RegExp(r'[\s₫]'), '');
    final hasComma = normalized.contains(',');
    final hasDot = normalized.contains('.');

    if (hasComma && hasDot) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      final decimalDigits = normalized.length - normalized.lastIndexOf(',') - 1;
      normalized = decimalDigits == 3
          ? normalized.replaceAll(',', '')
          : normalized.replaceAll(',', '.');
    } else if (hasDot) {
      final decimalDigits = normalized.length - normalized.lastIndexOf('.') - 1;
      if (decimalDigits == 3) {
        normalized = normalized.replaceAll('.', '');
      }
    }
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formProvider = ocrConfirmationFormProvider(widget.initialData);
    final formState = ref.read(formProvider);
    final updatedResult = OcrInvoiceResult(
      filename: widget.initialData.filename,
      taxCode: formState.taxCode.trim().isEmpty
          ? null
          : formState.taxCode.trim(),
      invoiceDate: formState.invoiceDate,
      totalAmount: _parseAmount(formState.totalAmount),
      needUserConfirmation: widget.initialData.needUserConfirmation,
    );

    late final LedgerEntry entry;
    try {
      entry = updatedResult.toLedgerEntry(category: formState.category);
    } on FormatException catch (error) {
      _showError(error.message);
      return;
    } on StateError catch (error) {
      _showError(error.message);
      return;
    }

    ref.read(formProvider.notifier).setSubmitting(true);
    try {
      final repository = ref.read(ledgerRepositoryProvider);
      if (_pendingExpenseId == null) {
        final expenseId = await repository.createOcrExpense(entry);
        if (mounted) {
          setState(() => _pendingExpenseId = expenseId);
        } else {
          _pendingExpenseId = expenseId;
        }
      }
      await repository.confirmExpense(_pendingExpenseId!);

      final entryDate = DateTime.parse(entry.entryDate);
      ref.invalidate(
        ledgerPageProvider(from: entryDate, to: entryDate, book: 'EXPENSE'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi sổ chi phí thành công.')),
      );
      Navigator.of(context).pop();
    } on LedgerException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Không thể ghi sổ chi phí: $error');
    } finally {
      if (mounted) {
        ref.read(formProvider.notifier).setSubmitting(false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ConfirmationNotice extends StatelessWidget {
  const _ConfirmationNotice();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 8),
            Expanded(
              child: Text('Vui lòng kiểm tra lại thông tin AI đã nhận diện.'),
            ),
          ],
        ),
      ),
    );
  }
}

final ocrConfirmationFormProvider = NotifierProvider.autoDispose
    .family<
      OcrConfirmationFormNotifier,
      OcrConfirmationFormState,
      OcrInvoiceResult
    >(OcrConfirmationFormNotifier.new);

class OcrConfirmationFormNotifier extends Notifier<OcrConfirmationFormState> {
  OcrConfirmationFormNotifier(this.initialData);

  final OcrInvoiceResult initialData;

  @override
  OcrConfirmationFormState build() {
    return OcrConfirmationFormState(
      taxCode: initialData.taxCode ?? '',
      invoiceDate: initialData.invoiceDate ?? '',
      totalAmount: initialData.totalAmount?.toStringAsFixed(0) ?? '',
    );
  }

  void updateTaxCode(String value) {
    state = state.copyWith(taxCode: value);
  }

  void updateInvoiceDate(String value) {
    state = state.copyWith(invoiceDate: value);
  }

  void updateTotalAmount(String value) {
    state = state.copyWith(totalAmount: value);
  }

  void updateCategory(String value) {
    state = state.copyWith(category: value);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }
}

class OcrConfirmationFormState {
  const OcrConfirmationFormState({
    required this.taxCode,
    required this.invoiceDate,
    required this.totalAmount,
    this.category = 'Khác',
    this.isSubmitting = false,
  });

  final String taxCode;
  final String invoiceDate;
  final String totalAmount;
  final String category;
  final bool isSubmitting;

  OcrConfirmationFormState copyWith({
    String? taxCode,
    String? invoiceDate,
    String? totalAmount,
    String? category,
    bool? isSubmitting,
  }) {
    return OcrConfirmationFormState(
      taxCode: taxCode ?? this.taxCode,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
