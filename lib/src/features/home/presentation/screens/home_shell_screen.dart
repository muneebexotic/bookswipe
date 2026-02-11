import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_theme.dart';

/// Home shell screen with bottom navigation bar
class HomeShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.overlayLight,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: theme.scaffoldBackgroundColor,
          indicatorColor: colorScheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: [
            NavigationDestination(
              icon: Icon(AppAssets.spiceOutlined,
                  color: colorScheme.onSurfaceVariant),
              selectedIcon:
                  Icon(AppAssets.discover, color: colorScheme.primary),
              label: AppStrings.navDiscover,
            ),
            NavigationDestination(
              icon: Icon(AppAssets.bookPlaceholder,
                  color: colorScheme.onSurfaceVariant),
              selectedIcon: Icon(AppAssets.library, color: colorScheme.primary),
              label: AppStrings.navLibrary,
            ),
            NavigationDestination(
              icon:
                  Icon(AppAssets.profile, color: colorScheme.onSurfaceVariant),
              selectedIcon: Icon(Icons.person, color: colorScheme.primary),
              label: AppStrings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
