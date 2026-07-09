import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // Slightly smaller labels when the user has large accessibility text.
    final labelSize =
        textScale >= 1.3 ? AppFontSizes.xs * 0.9 : AppFontSizes.sm;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(top: true, bottom: false, child: navigationShell),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        selectedFontSize: labelSize,
        unselectedFontSize: labelSize,
        iconSize: AppFontSizes.iconMd,
        selectedLabelStyle: AppTheme.textStyle(
          fontSize: labelSize,
          fontWeight: AppFontWeights.semibold,
        ).copyWith(overflow: TextOverflow.ellipsis),
        unselectedLabelStyle: AppTheme.textStyle(
          fontSize: labelSize,
          fontWeight: AppFontWeights.medium,
        ).copyWith(overflow: TextOverflow.ellipsis),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.home_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.home),
            ),
            label: 'Dashboard',
            tooltip: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.receipt_long_outlined),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.receipt_long),
            ),
            label: 'Debts',
            tooltip: 'Debts',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.people_outline),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.space1),
              child: Icon(Icons.people),
            ),
            label: 'Customers',
            tooltip: 'Customers',
          ),
        ],
      ),
    );
  }
}
