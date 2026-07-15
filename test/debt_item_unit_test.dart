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
      expect(DebtItemUnits.displayNameForQuantity('sack', 2), 'sack');
    });

    test('uses grammatically correct common unit labels for quantities', () {
      expect(
        DebtItemUnits.displayNameForQuantity(DebtItemUnits.piece, 1),
        'Piece',
      );
      expect(
        DebtItemUnits.displayNameForQuantity(DebtItemUnits.piece, 2),
        'Pieces',
      );
      expect(
        DebtItemUnits.displayNameForQuantity(DebtItemUnits.bottle, 2),
        'Bottles',
      );
      expect(
        DebtItemUnits.displayNameForQuantity(DebtItemUnits.box, 2),
        'Boxes',
      );
      expect(
        DebtItemUnits.displayNameForQuantity(DebtItemUnits.kilogram, 0.5),
        'kg',
      );
    });
  });
}
