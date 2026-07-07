import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final isWide = constraints.maxWidth >= 900;

        return ListView(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          children: [
            _buildHeader(context, isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildTypeGrid(isWide, isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildInfoCard(context, isTablet),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Site Registration',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: isTablet ? 32 : null,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Select the primary type of location you are registering. '
          'This determines what information we collect next.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeGrid(bool isWide, bool isTablet) {
    if (isWide) {
      // 2x2 grid on wide screens
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.8,
        children: SiteType.values
            .map(
              (type) => _SiteTypeCard(
                type: type,
                selected: selectedType == type,
                isTablet: isTablet,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTypeSelected(type);
                },
              ),
            )
            .toList(),
      );
    }

    // List on mobile/tablet
    return Column(
      children: SiteType.values
          .map(
            (type) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SiteTypeCard(
                type: type,
                selected: selectedType == type,
                isTablet: isTablet,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTypeSelected(type);
                },
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: isTablet ? 24 : 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Choose the category that best matches the site. '
              'Additional details specific to the selected type '
              'will be collected later in the registration process.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
                fontSize: isTablet ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
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
        return const Color(0xFFF59E0B); // Amber
      case SiteType.business:
        return const Color(0xFF3B82F6); // Blue
      case SiteType.church:
        return const Color(0xFF8B5CF6); // Purple
      case SiteType.school:
        return const Color(0xFF10B981); // Green
    }
  }

  String get description {
    switch (type) {
      case SiteType.house:
        return 'Residential household or homestead';
      case SiteType.business:
        return 'Shop, office, market or commercial premises';
      case SiteType.church:
        return 'Church, mosque or place of worship';
      case SiteType.school:
        return 'School, college or educational institution';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '${type.label}. $description',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: isTablet ? 32 : 28,
                    ),
                  ),
                  const SizedBox(width: 18),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: isTablet ? 18 : 16,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: isTablet ? 14 : 13,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Check indicator
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  if (!selected)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
