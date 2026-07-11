import 'package:flutter/material.dart';
import 'package:utang_tracker/core/utils/money.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(this.money, {super.key, this.style, this.color});

  final Money money;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      money.format(),
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
