import 'package:flutter/material.dart';

import '../models/site.dart';
import '../theme/app_theme.dart';

/// Responsive card displaying a site type, count and percentage.
/// Supports tap action and better empty states.
class SiteTypeCard extends StatelessWidget {
  final SiteType type;
  final int count;
  final double percentage;
  final VoidCallback? onTap;

  const SiteTypeCard({
    super.key,
    required this.type,
    required this.count,
    required this.percentage,
    this.onTap,
  });

  ({IconData icon, Color bg, Color fg}) get _style {
    switch (type) {
      case SiteType.house:
        return (
          icon: Icons.home_outlined,
          bg: AppColors.houseBg,
          fg: AppColors.houseFg,
        );
      case SiteType.business:
        return (
          icon: Icons.storefront_outlined,
          bg: AppColors.businessBg,
          fg: AppColors.businessFg,
        );
      case SiteType.church:
        return (
          icon: Icons.church_outlined,
          bg: AppColors.churchBg,
          fg: AppColors.churchFg,
        );
      case SiteType.school:
        return (
          icon: Icons.school_outlined,
          bg: AppColors.schoolBg,
          fg: AppColors.schoolFg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final isEmpty = count == 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEmpty ? AppColors.surfaceElevated : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmpty
                  ? AppColors.divider.withValues(alpha: 0.5)
                  : AppColors.divider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isCompact = width < 80;
              final isTablet = width > 120;

              final avatarSize = isTablet
                  ? 48.0
                  : isCompact
                  ? 36.0
                  : 40.0;
              final iconSize = isTablet
                  ? 24.0
                  : isCompact
                  ? 18.0
                  : 20.0;
              final countSize = isTablet
                  ? 22.0
                  : isCompact
                  ? 16.0
                  : 18.0;
              final labelSize = isTablet
                  ? 12.0
                  : isCompact
                  ? 10.0
                  : 11.0;
              final percentSize = isTablet
                  ? 11.0
                  : isCompact
                  ? 9.0
                  : 10.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.textSecondary.withValues(alpha: 0.1)
                          : s.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      s.icon,
                      color: isEmpty ? AppColors.textSecondary : s.fg,
                      size: iconSize,
                    ),
                  ),

                  SizedBox(height: isCompact ? 6 : 10),

                  // Count
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      count.toString(),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: countSize,
                        fontWeight: FontWeight.w800,
                        color: isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Label
                  Text(
                    type.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: labelSize,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: isCompact ? 6 : 10),

                  // Percentage badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: isCompact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: isEmpty
                          ? AppColors.textSecondary.withValues(alpha: 0.1)
                          : s.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      percentage == 0
                          ? '0%'
                          : '${percentage.toStringAsFixed(percentage < 10 ? 1 : 0)}%',
                      style: TextStyle(
                        color: isEmpty ? AppColors.textSecondary : s.fg,
                        fontSize: percentSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
