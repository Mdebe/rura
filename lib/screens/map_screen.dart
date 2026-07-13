import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:ruralmap/screens/household_details_screen.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  final int refreshToken;

  const MapScreen({super.key, this.refreshToken = 0});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _errorMessage;

  List<Site> _sites = [];
  List<Site> _localSites = [];
  List<Site> _firebaseSites = [];

  LatLng _currentLocation = const LatLng(-28.9575, 31.4687);
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _loadLocation();

      final results = await Future.wait([
        DBHelper.instance.getAllSites(),
        _loadFirebaseSites(),
      ]);

      _localSites = results[0] as List<Site>;
      _firebaseSites = results[1] as List<Site>;

      final Map<String, Site> mergedMap = {};
      for (final site in _firebaseSites) {
        final key = site.firestoreId ?? site.siteCode;
        if (key.isNotEmpty) mergedMap[key] = site;
      }
      for (final site in _localSites) {
        final key = site.firestoreId ?? site.siteCode;
        if (key.isNotEmpty && !mergedMap.containsKey(key)) {
          mergedMap[key] = site;
        }
      }

      if (!mounted) return;
      setState(() {
        _sites = mergedMap.values.toList();
        _loading = false;
      });
    } catch (error, stack) {
      debugPrint('MapScreen load failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Unable to load map data. Please check permissions and try again.';
        _loading = false;
      });
    }
  }

  Future<List<Site>> _loadFirebaseSites() async {
    try {
      final snapshot = await _firestore
          .collection('sites')
          .orderBy('registeredAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return Site.fromFirestore(doc);
            } catch (e) {
              debugPrint('Failed to parse site ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Site>()
          .toList();
    } catch (e) {
      debugPrint('Firebase sites load failed: $e');
      return [];
    }
  }

  Future<void> _loadLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _accuracy = pos.accuracy;
    } catch (error, stack) {
      debugPrint('MapScreen location load failed: $error\n$stack');
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _launchDirections(Site site) async {
    if (site.latitude == null || site.longitude == null) {
      _showSnack('No coordinates for this site');
      return;
    }

    final lat = site.latitude!;
    final lng = site.longitude!;
    final label = Uri.encodeComponent(site.name);

    final uris = [
      Uri.parse('google.navigation:q=$lat,$lng'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
      Uri.parse('https://www.openstreetmap.org/directions?to=$lat%2C$lng'),
    ];

    for (final uri in uris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          debugPrint('Launched directions with: $uri');
          return;
        }
      } catch (e) {
        debugPrint('Failed to launch $uri: $e');
        continue;
      }
    }

    await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
    _showSnack('Could not open Maps. Coordinates copied to clipboard.');
  }

  List<Marker> _buildMarkers() {
    return _sites
        .where((e) => e.latitude != null && e.longitude != null)
        .map(
          (site) => Marker(
            point: LatLng(site.latitude!, site.longitude!),
            width: 55,
            height: 55,
            child: GestureDetector(
              onTap: () => _showSite(site),
              child: Icon(
                Icons.location_on,
                color: _markerColor(site.type),
                size: 42,
              ),
            ),
          ),
        )
        .toList();
  }

  Color _markerColor(SiteType type) {
    switch (type) {
      case SiteType.house:
        return Colors.green;
      case SiteType.business:
        return Colors.orange;
      case SiteType.school:
        return Colors.blue;
      case SiteType.church:
        return Colors.purple;
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool showCopy = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: showCopy
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              _showSnack('Copied to clipboard');
            }
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (showCopy)
                      const Icon(Icons.copy, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSite(Site site) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work, size: 60, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                site.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(site.village, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  site.type.label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.badge, 'Site Code', site.siteCode),
              const SizedBox(height: 8),
              if (site.directions.isNotEmpty)
                _buildDetailRow(Icons.route, 'Directions', site.directions),
              if (site.directions.isNotEmpty) const SizedBox(height: 8),
              _buildDetailRow(
                Icons.person,
                'Created By',
                site.createdByName?.isEmpty ?? true
                    ? 'Unknown'
                    : site.createdByName!,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.calendar_today,
                'Registered',
                site.registeredAt.toLocal().toString().split(' ')[0],
              ),
              if (site.latitude != null && site.longitude != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.gps_fixed,
                  'Coordinates',
                  '${site.latitude!.toStringAsFixed(6)}, ${site.longitude!.toStringAsFixed(6)}',
                  showCopy: true,
                ),
              ],
              if (site.householdHead != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  Icons.home,
                  'Household Head',
                  site.householdHead!,
                ),
              ],
              if (site.phoneNumber != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone, 'Phone', site.phoneNumber!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchDirections(site),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HouseholdDetailsScreen(
                              site: site,
                              onEdit: () {
                                Navigator.pop(context);
                                _load();
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Details'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 72,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 16,
              minZoom: 5,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.mfundo_iphisi.ruralcensus",
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 55,
                    height: 55,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 42,
                    ),
                  ),
                  ..._buildMarkers(),
                ],
              ),
            ],
          ),
          Positioned(
            top: 18,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gps_fixed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _accuracy == null
                            ? "Waiting for GPS..."
                            : "GPS Accuracy: ${_accuracy!.toStringAsFixed(1)} m",
                      ),
                    ),
                    Chip(label: Text("${_sites.length} Sites")),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "gps",
            onPressed: () async {
              await _loadLocation();
              _mapController.move(_currentLocation, 18);
              if (mounted) setState(() {});
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: "zoomIn",
            onPressed: () {
              final camera = _mapController.camera;
              _mapController.move(camera.center, camera.zoom + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: "zoomOut",
            onPressed: () {
              final camera = _mapController.camera;
              _mapController.move(camera.center, camera.zoom - 1);
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
