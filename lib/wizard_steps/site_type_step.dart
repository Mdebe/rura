import 'package:flutter/material.dart';

import '../../models/site.dart';
import '../../theme/app_theme.dart';

/// Step 1 - Select the type of site being registered.
class SiteTypeStep extends StatelessWidget {
  final SiteType selectedType;
  final ValueChanged<SiteType> onTypeSelected;

  const SiteTypeStep({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 700;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          "Site Registration",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Select the primary type of location you are registering. "
          "This determines the information collected in the next steps.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),
        ...SiteType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SiteTypeCard(
              type: type,
              selected: selectedType == type,
              isTablet: isTablet,
              onTap: () => onTypeSelected(type),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.shade100,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Choose the category that best matches the site. "
                  "Additional details specific to the selected type "
                  "will be collected later in the registration process.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SiteTypeCard extends StatelessWidget {
  final SiteType type;
  final bool selected;
  final bool isTablet;
  final VoidCallback onTap;

  const _SiteTypeCard({
    required this.type,
    required this.selected,
    required this.isTablet,
    required this.onTap,
  });

  IconData get icon {
    switch (type) {
      case SiteType.house:
        return Icons.home_rounded;
      case SiteType.business:
        return Icons.store_rounded;
      case SiteType.church:
        return Icons.church_rounded;
      case SiteType.school:
        return Icons.school_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case SiteType.house:
        return Colors.orange;
      case SiteType.business:
        return Colors.blue;
      case SiteType.church:
        return Colors.purple;
      case SiteType.school:
        return Colors.green;
    }
  }

  String get description {
    switch (type) {
      case SiteType.house:
        return "Residential household or homestead.";
      case SiteType.business:
        return "Shop, office, market or commercial premises.";
      case SiteType.church:
        return "Church, mosque or place of worship.";
      case SiteType.school:
        return "School, college or educational institution.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.divider,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 22 : 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 30 : 26,
                backgroundColor: iconColor.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: isTablet ? 30 : 26,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: selected
                    ? Container(
                        key: const ValueKey("selected"),
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Container(
                        key: const ValueKey("unselected"),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade400,
                          ),
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