import 'package:flutter/material.dart';

import '../models/site.dart';
import '../theme/app_theme.dart';

/// Responsive card displaying a site type, count and percentage.
class SiteTypeCard extends StatelessWidget {
  final SiteType type;
  final int count;
  final double percentage;

  const SiteTypeCard({
    super.key,
    required this.type,
    required this.count,
    required this.percentage,
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

    final width = MediaQuery.of(context).size.width;

    final isSmall = width < 360;
    final isTablet = width >= 700;

    final avatarRadius = isTablet
        ? 24.0
        : isSmall
            ? 16.0
            : 18.0;

    final iconSize = isTablet
        ? 24.0
        : isSmall
            ? 16.0
            : 18.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: s.bg,
            child: Icon(
              s.icon,
              color: s.fg,
              size: iconSize,
            ),
          ),

          SizedBox(height: isSmall ? 8 : 10),

          LayoutBuilder(
  builder: (context, constraints) {
    double fontSize;

    if (constraints.maxWidth < 70) {
      fontSize = 14;
    } else if (constraints.maxWidth < 90) {
      fontSize = 16;
    } else {
      fontSize = 18;
    }

    return Text(
      '$count',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  },
),

          const SizedBox(height: 4),

          Text(
            type.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              color: AppColors.textSecondary,
            ),
          ),

          SizedBox(height: isSmall ? 8 : 12),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 6 : 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: s.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: s.fg,
                  fontSize: isSmall ? 10 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}