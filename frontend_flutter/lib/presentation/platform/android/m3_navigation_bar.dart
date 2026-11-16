import 'package:flutter/material.dart';

/// Data model representing a navigation destination for Otto Android M3 interfaces.
class M3NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int? badgeCount;
  final bool showBadgeDot;
  final String? tooltip;

  const M3NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount,
    this.showBadgeDot = false,
    this.tooltip,
  });
}

/// Official Android Material Design 3 Bottom NavigationBar with pill indicator
/// and dynamic numeric/dot badges for Otto Git Stacking workflows.
class M3BottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<M3NavigationItem> items;
  final Color? backgroundColor;

  const M3BottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationBar(
      height: 80,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainer,
      surfaceTintColor: colorScheme.surfaceTint,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: items.map((item) {
        Widget unselectedIcon = Icon(item.icon);
        Widget selectedIcon = Icon(item.selectedIcon);

        if (item.badgeCount != null && item.badgeCount! > 0) {
          unselectedIcon = Badge.count(
            count: item.badgeCount!,
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            child: unselectedIcon,
          );
          selectedIcon = Badge.count(
            count: item.badgeCount!,
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            child: selectedIcon,
          );
        } else if (item.showBadgeDot) {
          unselectedIcon = Badge(
            backgroundColor: colorScheme.tertiary,
            child: unselectedIcon,
          );
          selectedIcon = Badge(
            backgroundColor: colorScheme.tertiary,
            child: selectedIcon,
          );
        }

        return NavigationDestination(
          icon: unselectedIcon,
          selectedIcon: selectedIcon,
          label: item.label,
          tooltip: item.tooltip ?? item.label,
        );
      }).toList(),
    );
  }
}

/// Material Design 3 NavigationRail for Android Foldables (unfolded/landscape)
/// and Tablets (screen width >= 600dp).
class M3NavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<M3NavigationItem> items;
  final Widget? leading;
  final Widget? trailing;
  final bool extended;

  const M3NavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.leading,
    this.trailing,
    this.extended = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.secondaryContainer,
      indicatorShape: const StadiumBorder(),
      useIndicator: true,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      groupAlignment: -0.2,
      leading: leading,
      trailing: trailing,
      destinations: items.map((item) {
        Widget unselectedIcon = Icon(item.icon);
        Widget selectedIcon = Icon(item.selectedIcon);

        if (item.badgeCount != null && item.badgeCount! > 0) {
          unselectedIcon = Badge.count(
            count: item.badgeCount!,
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            child: unselectedIcon,
          );
          selectedIcon = Badge.count(
            count: item.badgeCount!,
            backgroundColor: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            child: selectedIcon,
          );
        } else if (item.showBadgeDot) {
          unselectedIcon = Badge(
            backgroundColor: colorScheme.tertiary,
            child: unselectedIcon,
          );
          selectedIcon = Badge(
            backgroundColor: colorScheme.tertiary,
            child: selectedIcon,
          );
        }

        return NavigationRailDestination(
          icon: unselectedIcon,
          selectedIcon: selectedIcon,
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}

/// Adaptive layout scaffold switching between bottom NavigationBar on standard phones
/// and NavigationRail on foldables or tablets.
class M3AdaptiveNavigationScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<M3NavigationItem> items;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? railLeading;
  final Widget? railTrailing;
  final double breakpoint;

  const M3AdaptiveNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.railLeading,
    this.railTrailing,
    this.breakpoint = 600.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= breakpoint;

        if (isWideScreen) {
          // Tablet / Foldable landscape layout with NavigationRail
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                M3NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  items: items,
                  leading: railLeading,
                  trailing: railTrailing,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
          );
        }

        // Standard Mobile Portrait layout with NavigationBar
        return Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: M3BottomNavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            items: items,
          ),
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
      },
    );
  }
}
