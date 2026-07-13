import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GeoRuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onMenuPressed; // For drawer hamburger
  final VoidCallback? onRefreshLocation;
  final bool showHamburger;
  final bool showLocationRefresh;
  final bool showActionsMenu;
  final bool isViewer; // Hides settings for viewers

  const GeoRuraAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.onMenuPressed,
    this.onRefreshLocation,
    this.showHamburger = false,
    this.showLocationRefresh = false,
    this.showActionsMenu = true,
    this.isViewer = false,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom != null ? 48 : 0));

  @override
  Widget build(BuildContext context) {
    final List<Widget> allActions = [];

    if (showLocationRefresh) {
      allActions.add(
        IconButton(
          icon: const Icon(Icons.my_location_rounded),
          tooltip: 'Refresh Location',
          onPressed: onRefreshLocation,
        ),
      );
    }

    if (actions != null) {
      allActions.addAll(actions!);
    }

    if (showActionsMenu) {
      allActions.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          tooltip: 'More options',
          onSelected: (value) => _handleMenuSelection(context, value),
          itemBuilder: (context) => _buildMenuItems(),
        ),
      );
    }

    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: _buildLeading(context),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_work_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'GeoRura',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'BETA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle ?? title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: allActions.isNotEmpty ? allActions : null,
      bottom: bottom,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showHamburger) {
      return IconButton(
        icon: const Icon(Icons.menu_rounded),
        tooltip: 'Menu',
        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
      );
    }

    return null;
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'profile',
        child: ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Profile'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ];

    // Hide settings for viewers
    if (!isViewer) {
      items.add(
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      );
    }

    items.addAll([
      const PopupMenuItem(
        value: 'about',
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About GeoRura'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ]);

    return items;
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        Navigator.pushNamed(context, '/profile');
        break;
      case 'settings':
        if (!isViewer) Navigator.pushNamed(context, '/settings');
        break;
      case 'help':
        Navigator.pushNamed(context, '/help');
        break;
      case 'terms':
        Navigator.pushNamed(context, '/terms');
        break;
      case 'privacy':
        Navigator.pushNamed(context, '/privacy');
        break;
      case 'about':
        _showAboutDialog(context);
        break;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'GeoRura',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.home_work_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      applicationLegalese: '© 2026 amaphisi\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'GeoRura is a rural household mapping and data collection platform for South African municipalities.',
        ),
      ],
    );
  }
}
