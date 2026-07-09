import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';

enum AppMoneySize { sm, md, lg, xl, display }

class AppMoneyText extends StatelessWidget {
  final double amount;
  final AppMoneySize size;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  /// When true, scales the amount down to fit available width instead of
  /// overflowing. Prefer keeping this on in rows and narrow cards.
  final bool fit;

  const AppMoneyText({
    super.key,
    required this.amount,
    this.size = AppMoneySize.md,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.fit = true,
  });

  double get _fontSize => switch (size) {
        AppMoneySize.sm => AppFontSizes.sm,
        AppMoneySize.md => AppFontSizes.md,
        AppMoneySize.lg => AppFontSizes.xl,
        AppMoneySize.xl => AppFontSizes.x3l,
        AppMoneySize.display => AppFontSizes.display,
      };

  FontWeight get _weight =>
      fontWeight ??
      switch (size) {
        AppMoneySize.sm => AppFontWeights.semibold,
        AppMoneySize.md => AppFontWeights.semibold,
        AppMoneySize.lg => AppFontWeights.bold,
        AppMoneySize.xl => AppFontWeights.bold,
        AppMoneySize.display => AppFontWeights.bold,
      };

  @override
  Widget build(BuildContext context) {
    final text = Text(
      formatPeso(amount),
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: AppTheme.textStyle(
        fontSize: _fontSize,
        fontWeight: _weight,
        color: color ?? AppColors.textPrimary,
      ),
    );

    if (!fit) return text;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: _alignment,
      child: text,
    );
  }

  Alignment get _alignment {
    return switch (textAlign) {
      TextAlign.center => Alignment.center,
      TextAlign.right || TextAlign.end => Alignment.centerRight,
      _ => Alignment.centerLeft,
    };
  }
}
