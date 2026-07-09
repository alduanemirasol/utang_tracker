import 'package:flutter/widgets.dart';

/// Logical-width tiers for adaptive layouts (dp).
enum AppWidthClass {
  /// Narrow phones (under 360dp), e.g. 320dp devices.
  compact,

  /// Typical phones (360–599dp).
  medium,

  /// Tablets and wide landscape (≥ 600dp).
  expanded,
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMax = 360;
  static const double mediumMax = 600;

  static AppWidthClass widthClassFor(double width) {
    if (width < compactMax) return AppWidthClass.compact;
    if (width < mediumMax) return AppWidthClass.medium;
    return AppWidthClass.expanded;
  }

  static AppWidthClass of(BuildContext context) {
    return widthClassFor(MediaQuery.sizeOf(context).width);
  }
}
