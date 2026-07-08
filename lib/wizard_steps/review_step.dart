import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/site.dart';
// Use shared model
import '../../theme/app_theme.dart';

/// Step 7 — final read-only summary shown before saving locally.
/// Now includes income, employment, road access, and landmark distances.
class ReviewStep extends StatelessWidget {
  final SiteType selectedType;
  final String name;
  final String village;
  final String ward;
  final String address;
  final String householdHead;
  final int? householdSize;
  final String phoneNumber;

  // Demographics
  final int? males;
  final int? females;
  final int? children;
  final int? adults;
  final int? pensioners;
  final int? chronicMembers;

  // Income & Employment
  final String? incomeBracket;
  final int? employedCount;
  final int? unemployedCount;
  final int? grantRecipients;

  // Road & Access
  final Map<String, dynamic>? roadAccess;
  final List<Map<String, dynamic>>? landmarkAccesses;

  // Services
  final List<Map<String, dynamic>>? services;
  final String? notes;

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
    this.males,
    this.females,
    this.children,
    this.adults,
    this.pensioners,
    this.chronicMembers,
    this.incomeBracket,
    this.employedCount,
    this.unemployedCount,
    this.grantRecipients,
    this.roadAccess,
    this.landmarkAccesses,
    this.services,
    this.notes,
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

  String _formatDistance(double? km) {
    if (km == null) return 'Not specified';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatMinutes(int? min) {
    if (min == null) return 'Not specified';
    if (min < 60) return '$min min';
    final hours = min ~/ 60;
    final mins = min % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
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
                if (males != null || females != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Demographics',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (males != null || females != null)
                    _infoRow('Gender', 'M: ${males ?? 0}, F: ${females ?? 0}'),
                  if (children != null || adults != null || pensioners != null)
                    _infoRow(
                      'Age Groups',
                      'Children: ${children ?? 0}, Adults: ${adults ?? 0}, Elderly: ${pensioners ?? 0}',
                    ),
                  if (chronicMembers != null && chronicMembers! > 0)
                    _infoRow('Chronic Illness', '$chronicMembers members'),
                ],
              ],
            ),

            // Income & Employment Section
            if (incomeBracket != null ||
                employedCount != null ||
                unemployedCount != null ||
                grantRecipients != null) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildInfoCard(
                title: 'Income & Employment',
                icon: Icons.payments_rounded,
                isTablet: isTablet,
                children: [
                  if (incomeBracket != null)
                    _infoRow('Monthly Income', incomeBracket!),
                  if (employedCount != null || unemployedCount != null)
                    _infoRow(
                      'Employment',
                      'Employed: ${employedCount ?? 0}, Unemployed: ${unemployedCount ?? 0}',
                    ),
                  if (grantRecipients != null && grantRecipients! > 0)
                    _infoRow('Grant Recipients', '$grantRecipients members'),
                ],
              ),
            ],

            // Road Access Section
            if (roadAccess != null) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildInfoCard(
                title: 'Road Access to Site',
                icon: Icons.add_road_rounded,
                isTablet: isTablet,
                children: [
                  _infoRow(
                    'Road Type',
                    roadAccess!['roadType'] ?? 'Not specified',
                  ),
                  _infoRow(
                    'Condition',
                    roadAccess!['condition'] ?? 'Not specified',
                  ),
                  _infoRow(
                    'Year-Round Access',
                    roadAccess!['yearRoundAccess'] == true
                        ? 'Yes - All weather'
                        : 'No - Seasonal issues',
                  ),
                  if (roadAccess!['distanceToTar'] != null)
                    _infoRow(
                      'Distance to Tar Road',
                      '${roadAccess!['distanceToTar']} km',
                    ),
                ],
              ),
            ],

            // Landmark Access Section
            if (landmarkAccesses != null && landmarkAccesses!.isNotEmpty) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildInfoCard(
                title: 'Distance to Key Landmarks',
                icon: Icons.place_rounded,
                isTablet: isTablet,
                children: landmarkAccesses!
                    .where((l) => l['distanceKm'] != null)
                    .map(
                      (l) => _infoRow(
                        l['name'] ?? 'Unknown',
                        '${_formatDistance(l['distanceKm'])} · ${_formatMinutes(l['travelMinutes'])}',
                        subtitle: l['mode'] != null ? 'via ${l['mode']}' : null,
                      ),
                    )
                    .toList(),
              ),
            ],

            // Services Section
            if (services != null && services!.isNotEmpty) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildInfoCard(
                title: 'Available Services',
                icon: Icons.miscellaneous_services_rounded,
                isTablet: isTablet,
                children: services!
                    .where((s) => s['available'] == true)
                    .map(
                      (s) => _infoRow(
                        s['name'] ?? 'Unknown',
                        s['quality'] != null
                            ? '${s['quality']}/5 stars'
                            : 'Available',
                      ),
                    )
                    .toList(),
              ),
            ],

            // Notes
            if (notes != null && notes!.isNotEmpty) ...[
              SizedBox(height: isTablet ? 20 : 16),
              _buildInfoCard(
                title: 'Additional Notes',
                icon: Icons.notes_rounded,
                isTablet: isTablet,
                children: [
                  Text(
                    notes!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ],

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
