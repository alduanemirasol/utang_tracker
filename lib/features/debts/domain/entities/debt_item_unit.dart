class DebtItemUnitOption {
  const DebtItemUnitOption({required this.value, required this.label});

  final String value;
  final String label;
}

/// Common selling units for sari-sari store debt items.
///
/// Units are stored as free text so a shop can also use a custom unit without
/// requiring a database migration.
class DebtItemUnits {
  DebtItemUnits._();

  static const String piece = 'piece';
  static const String pack = 'pack';
  static const String box = 'box';
  static const String bottle = 'bottle';
  static const String kilogram = 'kg';
  static const String gram = 'g';
  static const String liter = 'liter';
  static const String milliliter = 'ml';
  static const String can = 'can';
  static const String sachet = 'sachet';
  static const String bag = 'bag';
  static const String dozen = 'dozen';
  static const String tray = 'tray';
  static const String bundle = 'bundle';

  static const List<DebtItemUnitOption> common = [
    DebtItemUnitOption(value: piece, label: 'Piece'),
    DebtItemUnitOption(value: pack, label: 'Pack'),
    DebtItemUnitOption(value: box, label: 'Box'),
    DebtItemUnitOption(value: bottle, label: 'Bottle'),
    DebtItemUnitOption(value: kilogram, label: 'kg'),
    DebtItemUnitOption(value: gram, label: 'g'),
    DebtItemUnitOption(value: liter, label: 'Liter'),
    DebtItemUnitOption(value: milliliter, label: 'ml'),
    DebtItemUnitOption(value: can, label: 'Can'),
    DebtItemUnitOption(value: sachet, label: 'Sachet'),
    DebtItemUnitOption(value: bag, label: 'Bag'),
    DebtItemUnitOption(value: dozen, label: 'Dozen'),
    DebtItemUnitOption(value: tray, label: 'Tray'),
    DebtItemUnitOption(value: bundle, label: 'Bundle'),
  ];

  static bool isCommon(String value) {
    return common.any((option) => option.value == value);
  }

  static String displayName(String value) {
    final normalized = normalize(value);
    for (final option in common) {
      if (option.value == normalized) return option.label;
    }
    return value.trim();
  }

  static String normalize(String value) {
    final trimmed = value.trim();
    for (final option in common) {
      if (option.value.toLowerCase() == trimmed.toLowerCase() ||
          option.label.toLowerCase() == trimmed.toLowerCase()) {
        return option.value;
      }
    }
    return trimmed;
  }
}
