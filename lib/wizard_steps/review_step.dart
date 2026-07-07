import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/site.dart';
import '../../theme/app_theme.dart';
import '../screens/register_site_screen.dart'; // For ServiceAvailability

/// Step 7 — final read-only summary shown before saving locally.
class ReviewStep extends StatelessWidget {
  final SiteType selectedType;
  final String name;
  final String village;
  final String ward;
  final String address;
  final String householdHead;
  final int? householdSize;
  final String phoneNumber;
  final List<ServiceAvailability> services;
  final List<String> photoPaths;
  final String siteCode;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  const ReviewStep({
    super.key,
    required this.selectedType,
    required this.name,
    required this.village,
    required this.ward,
    required this.address,
    required this.householdHead,
    required this.householdSize,
    required this.phoneNumber,
    required this.services,
    required this.photoPaths,
    required this.siteCode,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  void _copySiteCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: siteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Site ID copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableServices = services.where((s) => s.available).toList();
    final avgQuality =
        availableServices
            .where((s) => s.quality != null)
            .map((s) => s.quality!)
            .fold<double>(0, (a, b) => a + b) /
        (availableServices.where((s) => s.quality != null).length).clamp(
          1,
          double.infinity,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        final padding = isTablet ? 24.0 : 16.0;

        return ListView(
          padding: EdgeInsets.all(padding),
          children: [
            _buildHeader(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildIdCard(context, isTablet),
            SizedBox(height: isTablet ? 20 : 16),
            _buildInfoCard(
              title: 'Site Details',
              icon: Icons.info_rounded,
              isTablet: isTablet,
              children: [
                _infoRow('Type', selectedType.label),
                _infoRow('Name', name),
                _infoRow('Village', village),
                _infoRow('Ward', ward),
                if (address.isNotEmpty) _infoRow('Address', address),
                if (latitude != null && longitude != null)
                  _infoRow(
                    'GPS Coordinates',
                    '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                    subtitle: accuracy != null
                        ? 'Accuracy: ±${accuracy!.toStringAsFixed(1)}m'
                        : null,
                  ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildInfoCard(
              title: 'Household Information',
              icon: Icons.groups_rounded,
              isTablet: isTablet,
              children: [
                _infoRow(
                  'Household Head',
                  householdHead.isEmpty ? 'Not provided' : householdHead,
                ),
                _infoRow(
                  'Household Size',
                  householdSize?.toString() ?? 'Not provided',
                ),
                if (phoneNumber.isNotEmpty) _infoRow('Phone', phoneNumber),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildServicesCard(availableServices, avgQuality, isTablet),
            if (photoPaths.isNotEmpty) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildPhotoGallery(isTablet),
            ],
            SizedBox(height: isTablet ? 24 : 20),
            _buildWarningBanner(isTablet),
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
          'Review & Submit',
          style: TextStyle(
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verify all information is correct before saving to your device.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 15 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIdCard(BuildContext context, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Digital Site ID',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 15 : 14,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _copySiteCode(context),
                icon: const Icon(
                  Icons.copy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Copy ID',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            siteCode,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isTablet ? 24 : 20,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required bool isTablet,
    required List<Widget> children,
  }) {
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
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 17 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
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

  Widget _buildServicesCard(
    List<ServiceAvailability> availableServices,
    double avgQuality,
    bool isTablet,
  ) {
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
              Icon(Icons.checklist_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Services & Infrastructure',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 17 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (availableServices.isEmpty)
            Text(
              'No services selected',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableServices.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (service.quality != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        Text(
                          ' ${service.quality}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
            if (availableServices.any((s) => s.quality != null)) ...[
              const SizedBox(height: 12),
              Text(
                'Average Quality: ${avgQuality.toStringAsFixed(1)}/5.0',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(bool isTablet) {
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
              Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Site Photos (${photoPaths.length})',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 17 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: photoPaths.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(photoPaths[index]),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Data will be saved locally on this device. Sync to server when online.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTablet ? 14 : 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
