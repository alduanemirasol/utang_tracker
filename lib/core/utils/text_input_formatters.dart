import 'package:flutter/services.dart';

class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');

    if (raw.isEmpty || raw == '-') return TextEditingValue.empty;
    if (!RegExp(r'^-?\d*\.?\d*$').hasMatch(raw)) return oldValue;

    int rawPos = 0;
    for (
      int characterIndex = 0;
      characterIndex < newValue.selection.baseOffset &&
          characterIndex < newValue.text.length;
      characterIndex++
    ) {
      if (newValue.text[characterIndex] != ',') rawPos++;
    }

    final negative = raw.startsWith('-');
    final cleaned = negative ? raw.substring(1) : raw;
    final dotIndex = cleaned.indexOf('.');
    final intPart = dotIndex == -1 ? cleaned : cleaned.substring(0, dotIndex);
    final decPart = dotIndex == -1 ? '' : cleaned.substring(dotIndex);
    final formattedInt = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    );
    final formatted = '${negative ? '-' : ''}$formattedInt$decPart';

    int cursor = 0;
    int seen = 0;
    while (cursor < formatted.length && seen < rawPos) {
      if (formatted[cursor] != ',') seen++;
      cursor++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursor.clamp(0, formatted.length),
      ),
    );
  }
}

class NoEmojiInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\u{200D}]',
        unicode: true,
      ),
      '',
    );
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
