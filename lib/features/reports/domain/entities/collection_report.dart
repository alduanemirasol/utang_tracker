import 'package:equatable/equatable.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';

class CustomerCollection extends Equatable {
  const CustomerCollection({
    required this.customerName,
    required this.total,
    required this.paymentCount,
  });

  final String customerName;
  final Money total;
  final int paymentCount;

  @override
  List<Object?> get props => [customerName, total, paymentCount];
}

class OverdueBucket extends Equatable {
  const OverdueBucket({
    required this.label,
    required this.total,
    required this.debtCount,
  });

  final String label;
  final Money total;
  final int debtCount;

  @override
  List<Object?> get props => [label, total, debtCount];
}

class CollectionReport extends Equatable {
  const CollectionReport({
    required this.period,
    required this.collectedTotal,
    required this.paymentCount,
    required this.perCustomer,
    required this.overdueBuckets,
  });

  final CollectionPeriod period;
  final Money collectedTotal;
  final int paymentCount;
  final List<CustomerCollection> perCustomer;
  final List<OverdueBucket> overdueBuckets;

  int get overdueDebtCount =>
      overdueBuckets.fold(0, (sum, bucket) => sum + bucket.debtCount);

  @override
  List<Object?> get props => [
    period,
    collectedTotal,
    paymentCount,
    perCustomer,
    overdueBuckets,
  ];
}