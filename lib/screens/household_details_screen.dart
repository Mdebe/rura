import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/site.dart';

class HouseholdDetailsScreen extends StatelessWidget {
  final Site site;
  final VoidCallback? onEdit;

  const HouseholdDetailsScreen({
    super.key,
    required this.site,
    this.onEdit,
  });

  Widget _detailTile(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    Widget? trailing,
    bool copyable = false,
    required BuildContext context,
  }) {
    final displayValue = value.isEmpty ? "Not provided" : value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 15,
                  color: onTap != null ? Colors.blue.shade700 : Colors.black87,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (copyable && value.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied')),
                  );
                },
              ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (site.imagePath == null || site.imagePath!.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera, size: 70, color: Colors.grey),
              SizedBox(height: 8),
              Text('No image', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _FullImageScreen(imagePath: site.imagePath!),
          ),
        );
      },
      child: Hero(
        tag: site.imagePath!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(site.imagePath!),
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    if (site.latitude == null || site.longitude == null) return;
    final lat = site.latitude!;
    final lng = site.longitude!;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchOSM() async {
    if (site.latitude == null || site.longitude == null) return;
    final lat = site.latitude!;
    final lng = site.longitude!;
    final uri = Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showNavigationOptions(BuildContext context) async {
    if (site.latitude == null || site.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates not available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(context);
                _launchGoogleMaps();
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('OpenStreetMap'),
              onTap: () {
                Navigator.pop(context);
                _launchOSM();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Site Code: ${site.siteCode}'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: site.siteCode,
              version: QrVersions.auto,
              size: 220,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _buildShareText() {
    final gps = site.latitude != null && site.longitude != null
        ? '${site.latitude!.toStringAsFixed(6)}, ${site.longitude!.toStringAsFixed(6)}'
        : 'No GPS';
    return '''
GeoRura Household Record
Name: ${site.name}
Code: ${site.siteCode}
Type: ${site.type.label}
Head: ${site.householdHead ?? 'N/A'}
Phone: ${site.phoneNumber ?? 'N/A'}
Size: ${site.householdSize?.toString() ?? 'N/A'}
Location: ${site.village}, ${site.ward}, ${site.municipality}
GPS: $gps
Address: ${site.address ?? 'N/A'}
Notes: ${site.notes ?? 'None'}
Registered: ${site.registeredAt.day}/${site.registeredAt.month}/${site.registeredAt.year}
''';
  }

  Future<void> _shareVia(BuildContext context) async {
    final text = _buildShareText();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share...'),
              onTap: () {
                Navigator.pop(context);
                Share.share(text, subject: 'Household: ${site.name}');
              },
            ),
            if (site.phoneNumber?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.sms),
                title: const Text('SMS'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(Uri.parse('sms:${site.phoneNumber}?body=${Uri.encodeComponent(text)}'));
                },
              ),
            if (site.phoneNumber?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  final phone = site.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
                  launchUrl(Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(text)}'));
                },
              ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri(
                  scheme: 'mailto',
                  query: 'subject=Household: ${site.name}&body=${Uri.encodeComponent(text)}',
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGPS = site.latitude != null && site.longitude != null;
    final hasImage = site.imagePath?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _shareVia(context),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Household',
              onPressed: onEdit,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImage(context),
            const SizedBox(height: 16),

            // Header card
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          site.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: site.isSynced ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              site.isSynced ? Icons.cloud_done : Icons.cloud_off,
                              size: 16,
                              color: site.isSynced ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              site.isSynced ? 'Synced' : 'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: site.isSynced ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.location_city, size: 18),
                        label: Text(site.type.label),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.qr_code, size: 18),
                        label: const Text('Show QR'),
                        onPressed: () => _showQRCode(context),
                      ),
                      if (hasGPS)
                        ActionChip(
                          avatar: const Icon(Icons.directions, size: 18),
                          label: const Text('Navigate'),
                          onPressed: () => _showNavigationOptions(context),
                        ),
                      if (site.firestoreId != null)
                        ActionChip(
                          avatar: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy ID'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: site.firestoreId!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Firestore ID copied')),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${site.village}, ${site.ward}',
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Registered: ${site.registeredAt.day}/${site.registeredAt.month}/${site.registeredAt.year}",
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Household Info
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Household Information", Icons.family_restroom),
                  _detailTile(Icons.person, "Household Head", site.householdHead ?? "", context: context),
                  _detailTile(Icons.groups, "Household Size", site.householdSize?.toString() ?? "", context: context),
                  _detailTile(
                    Icons.phone,
                    "Phone Number",
                    site.phoneNumber ?? "",
                    onTap: site.phoneNumber?.isNotEmpty == true
                        ? () => launchUrl(Uri.parse('tel:${site.phoneNumber}'))
                        : null,
                    copyable: true,
                    context: context,
                  ),
                ],
              ),
            ),

            // Location Details
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Administrative Location", Icons.location_on),
                  _detailTile(Icons.qr_code, "Site Code", site.siteCode, copyable: true, context: context, trailing: IconButton(
                    icon: const Icon(Icons.qr_code_2, size: 20),
                    onPressed: () => _showQRCode(context),
                  )),
                  _detailTile(Icons.map, "Province", site.province, context: context),
                  _detailTile(Icons.map, "District", site.district, context: context),
                  _detailTile(Icons.location_city, "Municipality", site.municipality, context: context),
                  _detailTile(Icons.flag, "Ward", site.ward, context: context),
                  _detailTile(Icons.groups, "Traditional Authority", site.traditionalAuthority, context: context),
                  _detailTile(Icons.home_work, "Section", site.section, context: context),
                  _detailTile(Icons.location_city, "Village", site.village, context: context),
                  _detailTile(Icons.location_pin, "Address", site.address ?? "", context: context),
                  _detailTile(Icons.place, "Landmark", site.landmark ?? "", context: context),
                ],
              ),
            ),

            // GPS
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("GPS Coordinates", Icons.gps_fixed),
                  _detailTile(
                    Icons.my_location,
                    "Latitude",
                    site.latitude?.toStringAsFixed(6) ?? "",
                    onTap: hasGPS ? () => _showNavigationOptions(context) : null,
                    copyable: hasGPS,
                    context: context,
                  ),
                  _detailTile(
                    Icons.my_location,
                    "Longitude",
                    site.longitude?.toStringAsFixed(6) ?? "",
                    onTap: hasGPS ? () => _showNavigationOptions(context) : null,
                    copyable: hasGPS,
                    context: context,
                  ),
                  if (hasGPS)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: () => _showNavigationOptions(context),
                        icon: const Icon(Icons.directions),
                        label: const Text('Navigate to Site'),
                      ),
                    ),
                ],
              ),
            ),

            // Notes
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Notes", Icons.description),
                  Text(
                    site.notes?.isEmpty ?? true ? "No notes provided" : site.notes!,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),

            // Metadata
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Record Details", Icons.info_outline),
                  _detailTile(Icons.badge, "Local ID", site.id?.toString() ?? "N/A", context: context),
                  _detailTile(Icons.cloud, "Firestore ID", site.firestoreId ?? "Not synced", copyable: site.firestoreId != null, context: context),
                  _detailTile(Icons.image, "Has Image", hasImage ? "Yes" : "No", context: context),
                  _detailTile(Icons.sync, "Sync Status", site.isSynced ? "Synced to cloud" : "Pending sync", context: context),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FullImageScreen extends StatelessWidget {
  final String imagePath;

  const _FullImageScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: Hero(
          tag: imagePath,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Image.file(File(imagePath)),
          ),
        ),
      ),
    );
  }
}