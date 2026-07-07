import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bottom navigation with a raised circular "Register" action in the
/// middle, matching the mock-up (Home / Search / + / Map / Reports).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onRegisterTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.home_outlined, label: 'Home', selected: currentIndex == 0, onTap: () => onTap(0)),
          _NavItem(icon: Icons.search, label: 'Search', selected: currentIndex == 1, onTap: () => onTap(1)),
          _CenterAction(onTap: onRegisterTap),
          _NavItem(icon: Icons.map_outlined, label: 'Map', selected: currentIndex == 3, onTap: () => onTap(3)),
         
          _NavItem(icon: Icons.person_outline, label: 'Profile', selected: currentIndex == 5, onTap: () => onTap(5)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white60;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
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
        width: 44,
        height: 44,
        decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
