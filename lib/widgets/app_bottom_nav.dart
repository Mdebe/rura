import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation with optional Admin tab and role-based center action.
/// Layout: Home / Search / [+ or Admin] / Map / Profile
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onRegisterTap;
  final bool isAdmin;
  final bool showRegisterAction;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onRegisterTap,
    this.isAdmin = false,
    this.showRegisterAction =
        true, // Admins can register, enumerators might not
  });

  @override
  Widget build(BuildContext context) {
    // Build items dynamically based on role
    final items = <Widget>[
      _NavItem(
        icon: Icons.home_outlined,
        label: 'Home',
        selected: currentIndex == 0,
        onTap: () => onTap(0),
      ),
      _NavItem(
        icon: Icons.search,
        label: 'Search',
        selected: currentIndex == 1,
        onTap: () => onTap(1),
      ),
    ];

    // Center slot: Register button or Admin tab
    if (showRegisterAction) {
      items.add(_CenterAction(onTap: onRegisterTap));
    } else if (isAdmin) {
      items.add(
        _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin',
          selected: currentIndex == 2,
          onTap: () => onTap(2),
        ),
      );
    } else {
      // Spacer if no center action
      items.add(const SizedBox(width: 48));
    }

    items.addAll([
      _NavItem(
        icon: Icons.map_outlined,
        label: 'Map',
        selected: currentIndex == (showRegisterAction || isAdmin ? 3 : 2),
        onTap: () => onTap(showRegisterAction || isAdmin ? 3 : 2),
      ),
      _NavItem(
        icon: Icons.person_outline,
        label: 'Profile',
        selected: currentIndex == (showRegisterAction || isAdmin ? 4 : 3),
        onTap: () => onTap(showRegisterAction || isAdmin ? 4 : 3),
      ),
    ]);

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final VoidCallback onTap;
  const _CenterAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
