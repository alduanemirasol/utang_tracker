import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/utils/debt_math.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';

void main() {
  group('DebtMath', () {
    test('total is sum of custom item prices', () {
      final total = DebtMath.computeTotal([
        Money.fromPesos(50),
        Money.fromPesos(25.50),
      ]);
      expect(total.centavos, 7550);
    });

    test('balance = total - paid', () {
      final balance = DebtMath.computeBalance(
        totalAmount: Money.fromPesos(100),
        paidAmount: Money.fromPesos(40),
      );
      expect(balance.centavos, 6000);
    });

    test('status derivation', () {
      expect(
        DebtMath.deriveStatus(
          totalAmount: Money.fromPesos(100),
          paidAmount: Money.zero(),
        ),
        DebtStatus.unpaid,
      );
      expect(
        DebtMath.deriveStatus(
          totalAmount: Money.fromPesos(100),
          paidAmount: Money.fromPesos(40),
        ),
        DebtStatus.partial,
      );
      expect(
        DebtMath.deriveStatus(
          totalAmount: Money.fromPesos(100),
          paidAmount: Money.fromPesos(100),
        ),
        DebtStatus.paid,
      );
    });
  });

  group('Money', () {
    test('parses peso strings', () {
      expect(Money.fromPesoString('12.50').centavos, 1250);
      expect(Money.fromPesoString('12').centavos, 1200);
    });

    test('parses comma-grouped and negative peso strings', () {
      expect(Money.fromPesoString('1,000.50').centavos, 100050);
      expect(Money.fromPesoString(' 1,234,567.89 ').centavos, 123456789);
      expect(Money.fromPesoString('-5').centavos, -500);
    });

    test('rejects empty and malformed peso strings', () {
      expect(() => Money.fromPesoString(''), throwsFormatException);
      expect(() => Money.fromPesoString('   '), throwsFormatException);
      expect(() => Money.fromPesoString('12.5.5'), throwsFormatException);
      expect(() => Money.fromPesoString('abc'), throwsFormatException);
    });

    test('rejects non-finite peso strings', () {
      expect(() => Money.fromPesoString('NaN'), throwsFormatException);
      expect(() => Money.fromPesoString('Infinity'), throwsFormatException);
      expect(() => Money.fromPesoString('-Infinity'), throwsFormatException);
    });

    test('fromPesos rounds to nearest centavo', () {
      expect(Money.fromPesos(0.1 + 0.2).centavos, 30);
      expect(Money.fromPesos(123.456).centavos, 12346);
    });

    test('formats with peso symbol', () {
      final formatted = Money.fromPesos(1500).format();
      expect(formatted.contains('1,500'), isTrue);
    });

    test('formats exact output', () {
      expect(Money.fromPesos(1500).format(), '₱1,500.00');
      expect(Money.fromPesos(0).format(), '₱0.00');
    });
  });
}
