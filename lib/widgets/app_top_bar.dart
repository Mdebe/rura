import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RuralMapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  const RuralMapAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = false,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom != null ? 48 : 0),
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
