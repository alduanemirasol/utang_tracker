import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';
import 'package:utang_tracker/features/customers/domain/customer_summary.dart';

class GetCustomerSummaryUseCase {
  final CustomerRepository _repository;

  GetCustomerSummaryUseCase(this._repository);

  Future<Result<CustomerSummary>> execute(String id) async {
    final customerResult = await _repository.getById(id);
    if (customerResult is Error) {
      return Error((customerResult as Error).failure);
    }
    final customer = (customerResult as Success).data;

    final debtsResult = await _repository.getDebtsByCustomerId(id);
    if (debtsResult is Error) {
      return Error((debtsResult as Error).failure);
    }
    final debtMaps = (debtsResult as Success).data;

    final totalDebts = debtMaps.length;
    final totalBalance = debtMaps.fold(
        0.0, (sum, m) => sum + ((m[columnBalance] as num).toDouble()));
    final totalPaid = debtMaps.fold(
        0.0, (sum, m) => sum + ((m[columnPaidAmount] as num).toDouble()));
    DateTime? lastTransactionDate;
    if (debtMaps.isNotEmpty) {
      final dates = debtMaps
          .map((m) => DateTime.parse(m[columnTransactionDate] as String))
          .toList()
        ..sort();
      lastTransactionDate = dates.last;
    }

    return Success(CustomerSummary(
      customer: customer,
      totalDebts: totalDebts,
      totalBalance: totalBalance,
      totalPaid: totalPaid,
      lastTransactionDate: lastTransactionDate,
    ));
  }
}
