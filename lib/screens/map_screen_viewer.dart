import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/site.dart';

class MapScreen extends StatefulWidget {
  final int refreshToken;
  final List<Site>? initialSites;

  const MapScreen({super.key, this.refreshToken = 0, this.initialSites});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLng _initialCenter = const LatLng(-29.85, 31.02); // Durban default
  double _initialZoom = 10.0;

  Stream<List<Site>> _sitesStream() {
    if (widget.initialSites != null) return Stream.value(widget.initialSites!);
    return FirebaseFirestore.instance
        .collection('sites')
        .orderBy('registeredAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) {
                try {
                  return Site.fromFirestore(d);
                } catch (_) {
                  return null;
                }
              })
              .whereType<Site>()
              .toList(),
        );
  }

  void _setMarkers(List<Site> sites) {
    final validSites = sites
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();

    final markers = validSites
        .map(
          (s) => Marker(
            point: LatLng(s.latitude!, s.longitude!),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showSiteBottomSheet(s),
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        )
        .toList();

    if (validSites.isNotEmpty) {
      _initialCenter = LatLng(
        validSites.first.latitude!,
        validSites.first.longitude!,
      );
      if (validSites.length > 1) {
        // fit bounds
        final bounds = LatLngBounds.fromPoints(
          validSites.map((s) => LatLng(s.latitude!, s.longitude!)).toList(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        });
      }
    }

    setState(() => _markers = markers);
  }

  Future<void> _launchGoogleMaps(Site site) async {
    if (site.latitude == null || site.longitude == null) {
      _showSnack('No coordinates for this site');
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${site.latitude},${site.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open Google Maps');
    }
  }

  Future<void> _launchOpenStreetMap(Site site) async {
    if (site.latitude == null || site.longitude == null) {
      _showSnack('No coordinates for this site');
      return;
    }
    // OSM directions via web
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions?to=${site.latitude}%2C${site.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open OpenStreetMap');
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showSiteBottomSheet(Site site) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                site.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.badge, 'Site Code', site.siteCode),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.location_city, 'Village', site.village),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.directions,
                'Directions',
                site.directions.isEmpty ? 'Not provided' : site.directions,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.person,
                'Created By',
                site.createdByName?.isEmpty ?? true
                    ? 'Unknown'
                    : site.createdByName!,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today,
                'Registered',
                site.registeredAt.toLocal().toString().split(' ')[0],
              ),
              if (site.latitude != null && site.longitude != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.gps_fixed,
                  'Coordinates',
                  '${site.latitude!.toStringAsFixed(6)}, ${site.longitude!.toStringAsFixed(6)}',
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchGoogleMaps(site),
                      icon: const Icon(Icons.map),
                      label: const Text('Google Maps'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchOpenStreetMap(site),
                      icon: const Icon(Icons.explore),
                      label: const Text('OpenStreetMap'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Sites Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on sites',
            onPressed: () {
              if (_markers.isNotEmpty) {
                final bounds = LatLngBounds.fromPoints(
                  _markers.map((m) => m.point).toList(),
                );
                _mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Site>>(
        stream: _sitesStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final sites = snap.data ?? [];
          _setMarkers(sites);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ruralmap', // required by OSM
              ),
              MarkerLayer(markers: _markers),
            ],
          );
        },
      ),
    );
  }
}
