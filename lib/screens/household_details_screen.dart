import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/site.dart';
import '../database/db_helper.dart';

class HouseholdDetailsScreen extends StatefulWidget {
  final Site site;
  final VoidCallback? onEdit;

  const HouseholdDetailsScreen({super.key, required this.site, this.onEdit});

  @override
  State<HouseholdDetailsScreen> createState() => _HouseholdDetailsScreenState();
}

class _HouseholdDetailsScreenState extends State<HouseholdDetailsScreen> {
  late Site _site;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _syncToFirebase() async {
    if (_site.isSynced) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Already synced')));
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    // ignore: unrelated_type_equality_checks
    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(const SnackBar(content: Text('No internet connection')));
      return;
    }

    setState(() => _syncing = true);

    try {
      final docRef = _site.firestoreId != null
          ? FirebaseFirestore.instance
                .collection('sites')
                .doc(_site.firestoreId)
          : FirebaseFirestore.instance.collection('sites').doc();

      final updatedSite = _site.copyWith(
        firestoreId: docRef.id,
        isSynced: true,
      );

      await docRef.set(updatedSite.toMap(), SetOptions(merge: true));

      if (_site.id != null) {
        await DBHelper.instance.updateSite(updatedSite.copyWith(id: _site.id));
      }

      if (mounted) {
        setState(() {
          _site = updatedSite;
          _syncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced to Firebase'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _syncing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$label copied')));
                },
              ),
            ?trailing,
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (_site.imagePath == null || _site.imagePath!.isEmpty) {
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
            builder: (_) => _FullImageScreen(imagePath: _site.imagePath!),
          ),
        );
      },
      child: Hero(
        tag: _site.imagePath!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(_site.imagePath!),
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
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }

  Future<void> _launchGoogleMaps() async {
    if (_site.latitude == null || _site.longitude == null) return;
    final lat = _site.latitude!;
    final lng = _site.longitude!;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchOSM() async {
    if (_site.latitude == null || _site.longitude == null) return;
    final lat = _site.latitude!;
    final lng = _site.longitude!;
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=18/$lat/$lng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showNavigationOptions(BuildContext context) async {
    if (_site.latitude == null || _site.longitude == null) {
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
        title: Text('Site Code: ${_site.siteCode}'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: _site.siteCode,
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
    final gps = _site.latitude != null && _site.longitude != null
        ? '${_site.latitude!.toStringAsFixed(6)}, ${_site.longitude!.toStringAsFixed(6)}'
        : 'No GPS';

    final servicesText = _site.services?.isNotEmpty == true
        ? _site.services!
              .map(
                (s) =>
                    '${s['name']}${s['rating'] != null ? ' (${s['rating']}/5)' : ''}',
              )
              .join(', ')
        : 'None';

    return '''
GeoRura Household Record
Name: ${_site.name}
Code: ${_site.siteCode}
Type: ${_site.type.label}
Head: ${_site.householdHead ?? 'N/A'}
Phone: ${_site.phoneNumber ?? 'N/A'}
 
 
 
Size: ${_site.householdSize?.toString() ?? 'N/A'}
Males: ${_site.males ?? 'N/A'}, Females: ${_site.females ?? 'N/A'}
Children: ${_site.children ?? 'N/A'}, Adults: ${_site.adults ?? 'N/A'}, Pensioners: ${_site.pensioners ?? 'N/A'}
Chronic Members: ${_site.chronicMembers ?? 'N/A'}
Income: ${_site.incomeBracket ?? 'N/A'}
Employed: ${_site.employedCount ?? 'N/A'}, Unemployed: ${_site.unemployedCount ?? 'N/A'}
Grant Recipients: ${_site.grantRecipients ?? 'N/A'}
Location: ${_site.village}, ${_site.ward}, ${_site.municipality}
GPS: $gps
Address: ${_site.address ?? 'N/A'}
Landmark: ${_site.landmark ?? 'N/A'}
Distance to Landmark: ${_site.distanceFromLandmark?.toStringAsFixed(1) ?? 'N/A'} km
Directions: ${_site.directions}
Services: $servicesText
Notes: ${_site.notes ?? 'None'}
Registered: ${_site.registeredAt.day}/${_site.registeredAt.month}/${_site.registeredAt.year}
 
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
                Share.share(text, subject: 'Household: ${_site.name}');
              },
            ),
            if (_site.phoneNumber?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.sms),
                title: const Text('SMS'),
                onTap: () {
                  Navigator.pop(context);
                  launchUrl(
                    Uri.parse(
                      'sms:${_site.phoneNumber}?body=${Uri.encodeComponent(text)}',
                    ),
                  );
                },
              ),
            if (_site.phoneNumber?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  final phone = _site.phoneNumber!.replaceAll(
                    RegExp(r'[^\d]'),
                    '',
                  );
                  launchUrl(
                    Uri.parse(
                      'https://wa.me/$phone?text=${Uri.encodeComponent(text)}',
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri(
                    scheme: 'mailto',
                    query:
                        'subject=Household: ${_site.name}&body=${Uri.encodeComponent(text)}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    if (_site.services == null || _site.services!.isEmpty) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Services & Utilities", Icons.electrical_services),
            const Text(
              'No services recorded',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("Services & Utilities", Icons.electrical_services),
          ..._site.services!.map((service) {
            final name = service['name'] ?? 'Unknown';
            final rating = service['rating'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (rating != null)
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGPS = _site.latitude != null && _site.longitude != null;
    final hasImage = _site.imagePath?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(_site.name),
        actions: [
          if (!_site.isSynced)
            IconButton(
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              tooltip: 'Sync Now',
              onPressed: _syncing ? null : _syncToFirebase,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () => _shareVia(context),
          ),
          if (widget.onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Household',
              onPressed: widget.onEdit,
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
                          _site.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _site.isSynced
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _site.isSynced
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              size: 16,
                              color: _site.isSynced
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _site.isSynced ? 'Synced' : 'Pending',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _site.isSynced
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
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
                        label: Text(_site.type.label),
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
                      if (_site.firestoreId != null)
                        ActionChip(
                          avatar: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy ID'),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _site.firestoreId!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Firestore ID copied'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_site.village}, ${_site.ward}',
                    style: const TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Registered: ${_site.registeredAt.day}/${_site.registeredAt.month}/${_site.registeredAt.year}",
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
                  _detailTile(
                    Icons.person,
                    "Household Head",
                    _site.householdHead ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.groups,
                    "Household Size",
                    _site.householdSize?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.phone,
                    "Phone Number",
                    _site.phoneNumber ?? "",
                    onTap: _site.phoneNumber?.isNotEmpty == true
                        ? () => launchUrl(Uri.parse('tel:${_site.phoneNumber}'))
                        : null,
                    copyable: true,
                    context: context,
                  ),
                ],
              ),
            ),

            // Demographics
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Demographics", Icons.people),
                  _detailTile(
                    Icons.male,
                    "Males",
                    _site.males?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.female,
                    "Females",
                    _site.females?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.child_care,
                    "Children",
                    _site.children?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.person,
                    "Adults",
                    _site.adults?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.elderly,
                    "Pensioners",
                    _site.pensioners?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.healing,
                    "Chronic Members",
                    _site.chronicMembers?.toString() ?? "",
                    context: context,
                  ),
                ],
              ),
            ),

            // Employment & Income
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Employment & Income", Icons.work_history),
                  _detailTile(
                    Icons.attach_money,
                    "Income Bracket",
                    _site.incomeBracket ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.work,
                    "Employed Count",
                    _site.employedCount?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.work_off,
                    "Unemployed Count",
                    _site.unemployedCount?.toString() ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.volunteer_activism,
                    "Grant Recipients",
                    _site.grantRecipients?.toString() ?? "",
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
                  _detailTile(
                    Icons.qr_code,
                    "Site Code",
                    _site.siteCode,
                    copyable: true,
                    context: context,
                    trailing: IconButton(
                      icon: const Icon(Icons.qr_code_2, size: 20),
                      onPressed: () => _showQRCode(context),
                    ),
                  ),
                  _detailTile(
                    Icons.map,
                    "Province",
                    _site.province,
                    context: context,
                  ),
                  _detailTile(
                    Icons.map,
                    "District",
                    _site.district,
                    context: context,
                  ),
                  _detailTile(
                    Icons.location_city,
                    "Municipality",
                    _site.municipality,
                    context: context,
                  ),
                  _detailTile(Icons.flag, "Ward", _site.ward, context: context),
                  _detailTile(
                    Icons.groups,
                    "Traditional Authority",
                    _site.traditionalAuthority,
                    context: context,
                  ),
                  _detailTile(
                    Icons.home_work,
                    "Section",
                    _site.section,
                    context: context,
                  ),
                  _detailTile(
                    Icons.location_city,
                    "Village",
                    _site.village,
                    context: context,
                  ),
                  _detailTile(
                    Icons.location_pin,
                    "Address",
                    _site.address ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.place,
                    "Landmark",
                    _site.landmark ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.social_distance,
                    "Distance to Landmark",
                    _site.distanceFromLandmark != null
                        ? '${_site.distanceFromLandmark!.toStringAsFixed(1)} km'
                        : "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.directions,
                    "Directions",
                    _site.directions,
                    context: context,
                  ),
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
                    _site.latitude?.toStringAsFixed(6) ?? "",
                    onTap: hasGPS
                        ? () => _showNavigationOptions(context)
                        : null,
                    copyable: hasGPS,
                    context: context,
                  ),
                  _detailTile(
                    Icons.my_location,
                    "Longitude",
                    _site.longitude?.toStringAsFixed(6) ?? "",
                    onTap: hasGPS
                        ? () => _showNavigationOptions(context)
                        : null,
                    copyable: hasGPS,
                    context: context,
                  ),
                  _detailTile(
                    Icons.height,
                    "Altitude",
                    _site.altitude?.toStringAsFixed(1) ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.speed,
                    "GPS Accuracy",
                    _site.accuracy?.toStringAsFixed(1) ?? "",
                    context: context,
                  ),
                  _detailTile(
                    Icons.access_time,
                    "Captured At",
                    _site.capturedAt != null
                        ? "${_site.capturedAt!.day}/${_site.capturedAt!.month}/${_site.capturedAt!.year} ${_site.capturedAt!.hour}:${_site.capturedAt!.minute.toString().padLeft(2, '0')}"
                        : "",
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

            // Services & Utilities - NEW SECTION
            _buildServicesSection(),

            // Notes
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle("Notes", Icons.description),
                  Text(
                    _site.notes?.isEmpty ?? true
                        ? "No notes provided"
                        : _site.notes!,
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
                  _detailTile(
                    Icons.badge,
                    "Local ID",
                    _site.id?.toString() ?? "N/A",
                    context: context,
                  ),
                  _detailTile(
                    Icons.cloud,
                    "Firestore ID",
                    _site.firestoreId ?? "Not synced",
                    copyable: _site.firestoreId != null,
                    context: context,
                  ),
                  _detailTile(
                    Icons.image,
                    "Has Image",
                    hasImage ? "Yes" : "No",
                    context: context,
                  ),
                  _detailTile(
                    Icons.sync,
                    "Sync Status",
                    _site.isSynced ? "Synced to cloud" : "Pending sync",
                    context: context,
                  ),

                  _detailTile(
                    Icons.description,
                    "Description",
                    _site.description ?? "",
                    context: context,
                  ),
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
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
