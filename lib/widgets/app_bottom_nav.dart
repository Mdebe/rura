import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation with dynamic Admin/Register center slot
/// Layout: Home / Search / [Register + Button] / Map / Profile
/// Admin accessed via Dashboard quick action only - not in bottom nav
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
    required this.isAdmin,
    this.showRegisterAction = true,
  });

  @override
  Widget build(BuildContext context) {
    // Map bottom nav indices to AppShellScreen indices
    // Bottom: 0=Home, 1=Search, 2=Register, 3=Map, 4=Profile
    // Shell:  0=Home, 1=Search, 2=Register, 3=Map, 4=Reports, 5=Profile, 6=Admin

    int mapShellToBottom(int shellIndex) {
      if (shellIndex <= 3) return shellIndex;
      if (shellIndex == 5) return 4; // Profile
      return 0; // Admin/Reports default to Home in nav
    }

    final bottomIndex = mapShellToBottom(currentIndex);

    final items = <Widget>[
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        selected: bottomIndex == 0,
        onTap: () => onTap(0),
      ),
      _NavItem(
        icon: Icons.search,
        activeIcon: Icons.search,
        label: 'Search',
        selected: bottomIndex == 1,
        onTap: () => onTap(1),
      ),
    ];

    // Center slot: Always register button if allowed
    if (showRegisterAction) {
      items.add(_CenterAction(onTap: onRegisterTap));
    } else {
      items.add(const SizedBox(width: 48)); // Spacer
    }

    items.addAll([
      _NavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
        label: 'Map',
        selected: bottomIndex == 3,
        onTap: () => onTap(3),
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        selected: bottomIndex == 4,
        onTap: () => onTap(5), // Profile is index 5 in shell
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
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
            Icon(selected ? activeIcon : icon, color: color, size: 22),
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
