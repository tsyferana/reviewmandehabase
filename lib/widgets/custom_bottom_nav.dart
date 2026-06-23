import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CustomBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 400),
        destinations: items.map((item) {
          return NavigationDestination(
            icon: item.badge != null && item.badge! > 0
                ? Badge(
                    label: Text('${item.badge}'),
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
            selectedIcon: item.badge != null && item.badge! > 0
                ? Badge(
                    label: Text('${item.badge}'),
                    child: Icon(item.selectedIcon ?? item.icon),
                  )
                : Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class CustomBottomNavItem {
  const CustomBottomNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final int? badge;
}
