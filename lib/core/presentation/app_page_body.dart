import 'package:flutter/material.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';

/// Centers content and clamps width on large screens.
///
/// Use for form bodies, detail scrolls, and list headers so layouts do not
/// stretch edge-to-edge on tablets.
class AppPageBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool applyPadding;
  final AlignmentGeometry alignment;

  const AppPageBody({
    super.key,
    required this.child,
    this.padding,
    this.applyPadding = true,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = AppResponsive.of(context);
    final content = applyPadding
        ? Padding(
            padding: padding ?? responsive.pagePadding(),
            child: child,
          )
        : child;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
        child: content,
      ),
    );
  }
}

/// Centers a scrollable/list child at the responsive max content width.
///
/// Horizontal padding is left to the child (e.g. [ListView.padding]) so
/// scrollbars and overscroll remain full-bleed when desired.
class AppConstrainedWidth extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry alignment;

  const AppConstrainedWidth({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppResponsive.of(context).contentMaxWidth;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
