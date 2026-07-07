import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A section title paired with a trailing action such as "View All"
/// or "Customise". Used above every dashboard section.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        if (actionLabel != null)
          InkWell(
            onTap: onAction,
            child: Row(
              children: [
                Text(actionLabel!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                if (actionIcon != null) ...[
                  const SizedBox(width: 2),
                  Icon(actionIcon, size: 16, color: AppColors.primary),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
