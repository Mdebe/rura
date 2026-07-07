import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Responsive Quick Action button used on the dashboard.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback? onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isSmall = width < 360;
    final isTablet = width >= 700;

    final bg = highlighted ? AppColors.primary : AppColors.surface;
    final fg = highlighted ? Colors.white : AppColors.primary;
    final subFg =
        highlighted ? Colors.white70 : AppColors.textSecondary;

    final padding = isSmall ? 10.0 : 14.0;
    final iconSize = isTablet
        ? 30.0
        : isSmall
            ? 22.0
            : 26.0;

    final avatarRadius = isTablet
        ? 20.0
        : isSmall
            ? 14.0
            : 16.0;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: highlighted
                ? null
                : Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              highlighted
                  ? CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.white,
                      child: Icon(
                        icon,
                        color: AppColors.primary,
                        size: iconSize - 6,
                      ),
                    )
                  : Icon(
                      icon,
                      color: fg,
                      size: iconSize,
                    ),

              SizedBox(height: isSmall ? 6 : 10),

              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: highlighted
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmall ? 12 : 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Flexible(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subFg,
                    fontSize: isSmall ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}