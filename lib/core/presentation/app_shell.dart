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
        selectedFontSize: AppFontSizes.sm,
        unselectedFontSize: AppFontSizes.sm,
        iconSize: AppFontSizes.iconMd,
        selectedLabelStyle: AppTheme.textStyle(
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.semibold,
        ),
        unselectedLabelStyle: AppTheme.textStyle(
          fontSize: AppFontSizes.sm,
          fontWeight: AppFontWeights.medium,
        ),
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
