import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';

enum AppMoneySize { sm, md, lg, xl, display }

class AppMoneyText extends StatelessWidget {
  final double amount;
  final AppMoneySize size;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  const AppMoneyText({
    super.key,
    required this.amount,
    this.size = AppMoneySize.md,
    this.color,
    this.fontWeight,
    this.textAlign,
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
    return Text(
      formatPeso(amount),
      textAlign: textAlign,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: _weight,
        color: color ?? AppColors.textPrimary,
      ),
    );
  }
}
