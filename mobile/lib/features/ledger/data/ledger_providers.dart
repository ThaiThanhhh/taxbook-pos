import 'package:dt13_pos/core/network/network_providers.dart';
import 'package:dt13_pos/features/ledger/data/ledger_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ledger_providers.g.dart';

@riverpod
LedgerRepository ledgerRepository(Ref ref) =>
    LedgerRepository(ref.watch(apiClientProvider));

@riverpod
Future<LedgerPage> ledgerPage(
  Ref ref, {
  required DateTime from,
  required DateTime to,
  String? book,
}) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return ref
      .watch(ledgerRepositoryProvider)
      .getLedgerPage(book: book, from: start, to: end);
}
