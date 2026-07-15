class DebtItemUnitOption {
  const DebtItemUnitOption({
    required this.value,
    required this.label,
    required this.pluralLabel,
  });

  final String value;
  final String label;
  final String pluralLabel;
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
    DebtItemUnitOption(value: piece, label: 'Piece', pluralLabel: 'Pieces'),
    DebtItemUnitOption(value: pack, label: 'Pack', pluralLabel: 'Packs'),
    DebtItemUnitOption(value: box, label: 'Box', pluralLabel: 'Boxes'),
    DebtItemUnitOption(value: bottle, label: 'Bottle', pluralLabel: 'Bottles'),
    DebtItemUnitOption(value: kilogram, label: 'kg', pluralLabel: 'kg'),
    DebtItemUnitOption(value: gram, label: 'g', pluralLabel: 'g'),
    DebtItemUnitOption(value: liter, label: 'Liter', pluralLabel: 'Liters'),
    DebtItemUnitOption(value: milliliter, label: 'ml', pluralLabel: 'ml'),
    DebtItemUnitOption(value: can, label: 'Can', pluralLabel: 'Cans'),
    DebtItemUnitOption(value: sachet, label: 'Sachet', pluralLabel: 'Sachets'),
    DebtItemUnitOption(value: bag, label: 'Bag', pluralLabel: 'Bags'),
    DebtItemUnitOption(value: dozen, label: 'Dozen', pluralLabel: 'Dozen'),
    DebtItemUnitOption(value: tray, label: 'Tray', pluralLabel: 'Trays'),
    DebtItemUnitOption(value: bundle, label: 'Bundle', pluralLabel: 'Bundles'),
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

  static String displayNameForQuantity(String value, double quantity) {
    final normalized = normalize(value);
    for (final option in common) {
      if (option.value == normalized) {
        return quantity == 1 ? option.label : option.pluralLabel;
      }
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
