import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';

void main() {
  group('DebtItemUnits', () {
    test('normalizes common unit labels to stored values', () {
      expect(DebtItemUnits.normalize('Bottle'), DebtItemUnits.bottle);
      expect(DebtItemUnits.normalize('KG'), DebtItemUnits.kilogram);
    });

    test('preserves custom units', () {
      expect(DebtItemUnits.normalize('sack'), 'sack');
      expect(DebtItemUnits.displayName('sack'), 'sack');
    });
  });
}
