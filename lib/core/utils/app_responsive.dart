import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_breakpoints.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';

/// Screen-size helpers derived from [MediaQuery].
class AppResponsive {
  final BuildContext context;

  const AppResponsive._(this.context);

  factory AppResponsive.of(BuildContext context) => AppResponsive._(context);

  Size get size => MediaQuery.sizeOf(context);

  AppWidthClass get widthClass => AppBreakpoints.of(context);

  bool get isCompact => widthClass == AppWidthClass.compact;

  bool get isMedium => widthClass == AppWidthClass.medium;

  bool get isExpanded => widthClass == AppWidthClass.expanded;

  bool get isLandscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  /// Approximate linear text scale (1.0 = default).
  double get textScale => MediaQuery.textScalerOf(context).scale(1);

  bool get isLargeText => textScale >= 1.3;

  double get contentMaxWidth => isExpanded
      ? AppSpacing.contentMaxWidthWide
      : AppSpacing.contentMaxWidth;

  double get horizontalPadding {
    if (isExpanded) return AppSpacing.space10;
    if (isCompact) return AppSpacing.space5;
    return AppSpacing.space7;
  }

  EdgeInsets pagePadding({
    double? top,
    double? bottom,
  }) {
    final h = horizontalPadding;
    return EdgeInsets.fromLTRB(
      h,
      top ?? h,
      h,
      bottom ?? h,
    );
  }

  /// Padding for scrollable forms; includes keyboard inset when present.
  EdgeInsets scrollPadding({
    double? top,
    double bottom = AppSpacing.space10,
  }) {
    final h = horizontalPadding;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return EdgeInsets.fromLTRB(
      h,
      top ?? h,
      h,
      bottom + keyboard,
    );
  }

  /// List content padding with optional FAB clearance.
  EdgeInsets listPadding({
    double top = 0,
    double bottom = AppSpacing.space80,
  }) {
    final h = horizontalPadding;
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }
}

extension AppResponsiveContext on BuildContext {
  AppResponsive get responsive => AppResponsive.of(this);
}
