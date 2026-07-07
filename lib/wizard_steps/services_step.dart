import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Service availability with quality rating
class ServiceAvailability {
  final String name;
  final bool available;
  final int? quality; // 1-5 rating when available

  const ServiceAvailability({
    required this.name,
    required this.available,
    this.quality,
  });

  ServiceAvailability copyWith({bool? available, int? quality}) {
    return ServiceAvailability(
      name: name,
      available: available ?? this.available,
      quality: quality,
    );
  }
}

/// Step 6 — toggles available services/infrastructure with quality ratings.
class ServicesStep extends StatelessWidget {
  final List<ServiceAvailability> services;
  final TextEditingController notesController;
  final ValueChanged<String> onToggleService;
  final void Function(String service, int rating) onRateService;

  const ServicesStep({
    super.key,
    required this.services,
    required this.notesController,
    required this.onToggleService,
    required this.onRateService,
  });

  static const Map<String, List<Map<String, dynamic>>> serviceCategories = {
    'Utilities': [
      {'name': 'Water', 'icon': Icons.water_drop_rounded},
      {'name': 'Electricity', 'icon': Icons.electrical_services_rounded},
      {'name': 'Sanitation', 'icon': Icons.wc_rounded},
      {'name': 'Waste Collection', 'icon': Icons.delete_rounded},
    ],
    'Communication': [
      {
        'name': 'Cellphone Network',
        'icon': Icons.signal_cellular_4_bar_rounded,
      },
      {'name': 'Internet/Fiber', 'icon': Icons.wifi_rounded},
      {'name': 'Postal Service', 'icon': Icons.local_post_office_rounded},
    ],
    'Access': [
      {'name': 'Tarred Road', 'icon': Icons.add_road_rounded},
      {'name': 'Public Transport', 'icon': Icons.directions_bus_rounded},
      {'name': 'Street Lights', 'icon': Icons.lightbulb_rounded},
    ],
    'Community': [
      {'name': 'School', 'icon': Icons.school_rounded},
      {'name': 'Clinic', 'icon': Icons.local_hospital_rounded},
      {'name': 'Police Station', 'icon': Icons.local_police_rounded},
      {'name': 'Community Hall', 'icon': Icons.holiday_village_rounded},
    ],
  };

  ServiceAvailability? _getService(String name) {
    try {
      return services.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final padding = isTablet ? 24.0 : 16.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            _buildHeader(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            ...serviceCategories.entries.map(
              (entry) =>
                  _buildCategory(context, entry.key, entry.value, isTablet),
            ),
            SizedBox(height: isTablet ? 28 : 20),
            _buildNotesSection(isTablet),
            const SizedBox(height: 16),
            _buildSummaryCard(isTablet),
          ],
        );
      },
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services & Infrastructure',
          style: TextStyle(
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select available services and rate their quality from 1-5 stars.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 15 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String category,
    List<Map<String, dynamic>> items,
    bool isTablet,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: 4,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isTablet ? 20 : 16,
            0,
            isTablet ? 20 : 16,
            isTablet ? 16 : 12,
          ),
          title: Text(
            category,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 17 : 16,
            ),
          ),
          subtitle: Text(
            '${items.where((i) => _getService(i['name'])?.available ?? false).length} of ${items.length} available',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          children: items
              .map((item) => _buildServiceTile(item, isTablet))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildServiceTile(Map<String, dynamic> item, bool isTablet) {
    final service = _getService(item['name']);
    final isAvailable = service?.available ?? false;
    final quality = service?.quality;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isAvailable
              ? AppColors.primary.withValues(alpha: 0.05)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isAvailable ? AppColors.primary : AppColors.divider,
            width: isAvailable ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              value: isAvailable,
              onChanged: (_) => onToggleService(item['name']),
              secondary: Icon(
                item['icon'],
                color: isAvailable
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              title: Text(
                item['name'],
                style: TextStyle(
                  fontWeight: isAvailable ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isTablet ? 15 : 14,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: 4,
              ),
            ),
            if (isAvailable) ...[
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Quality Rating',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          quality == null ? 'Not rated' : '$quality/5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFilled =
                            quality != null && starIndex <= quality;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onRateService(item['name'], starIndex);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isFilled
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                                size: isTablet ? 28 : 24,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 17 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Describe service quality, issues, or special conditions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: AppColors.surfaceElevated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isTablet) {
    final availableCount = services.where((s) => s.available).length;
    final totalCount = serviceCategories.values.expand((e) => e).length;
    final avgQuality =
        services
            .where((s) => s.available && s.quality != null)
            .map((s) => s.quality!)
            .fold<double>(0, (a, b) => a + b) /
        (services.where((s) => s.available && s.quality != null).length).clamp(
          1,
          double.infinity,
        );

    return Container(
      padding: EdgeInsets.all(isTablet ? 18 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$availableCount of $totalCount services available',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
                if (availableCount > 0)
                  Text(
                    'Average quality: ${avgQuality.toStringAsFixed(1)}/5',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
