import 'package:flutter/material.dart';
import '../models/site.dart';
import '../theme/app_theme.dart';

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
}

({Color bg, Color fg}) _badgeStyle(SiteType type) {
  switch (type) {
    case SiteType.house:
      return (bg: AppColors.houseBg, fg: AppColors.houseFg);
    case SiteType.business:
      return (bg: AppColors.businessBg, fg: AppColors.businessFg);
    case SiteType.church:
      return (bg: AppColors.churchBg, fg: AppColors.churchFg);
    case SiteType.school:
      return (bg: AppColors.schoolBg, fg: AppColors.schoolFg);
  }
}

IconData _typeIcon(SiteType type) {
  switch (type) {
    case SiteType.house:
      return Icons.home_outlined;
    case SiteType.business:
      return Icons.storefront_outlined;
    case SiteType.church:
      return Icons.church_outlined;
    case SiteType.school:
      return Icons.school_outlined;
  }
}

/// A single row in the "Recent Registrations" list: thumbnail, name,
/// village, a colored type badge and a relative timestamp.
class RecentRegistrationTile extends StatelessWidget {
  final Site site;
  final VoidCallback? onTap;

  const RecentRegistrationTile({super.key, required this.site, this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = _badgeStyle(site.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: badge.bg,
                child: Icon(_typeIcon(site.type), color: badge.fg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(site.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(site.village, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(20)),
                    child: Text(site.type.label, style: TextStyle(color: badge.fg, fontSize: 11)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeAgo(site.registeredAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
