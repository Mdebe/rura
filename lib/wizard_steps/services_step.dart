import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../theme/app_theme.dart';

/// Service availability with quality rating
class ServiceAvailability {
  final String name;
  final bool available;
  final int? quality;

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

  Map<String, dynamic> toMap() => {'name': name, 'quality': quality};

  factory ServiceAvailability.fromMap(Map<String, dynamic> map) {
    return ServiceAvailability(
      name: map['name'] ?? '',
      available: true,
      quality: map['quality'],
    );
  }
}

/// Road access details for site
class RoadAccess {
  final String roadType;
  final String condition;
  final bool yearRoundAccess;
  final int? distanceToTar;

  const RoadAccess({
    required this.roadType,
    required this.condition,
    required this.yearRoundAccess,
    this.distanceToTar,
  });

  RoadAccess copyWith({
    String? roadType,
    String? condition,
    bool? yearRoundAccess,
    int? distanceToTar,
  }) {
    return RoadAccess(
      roadType: roadType ?? this.roadType,
      condition: condition ?? this.condition,
      yearRoundAccess: yearRoundAccess ?? this.yearRoundAccess,
      distanceToTar: distanceToTar ?? this.distanceToTar,
    );
  }

  Map<String, dynamic> toMap() => {
    'roadType': roadType,
    'condition': condition,
    'yearRoundAccess': yearRoundAccess,
    'distanceToTar': distanceToTar,
  };

  factory RoadAccess.fromMap(Map<String, dynamic> map) {
    return RoadAccess(
      roadType: map['roadType'] ?? 'Gravel',
      condition: map['condition'] ?? 'Fair',
      yearRoundAccess: map['yearRoundAccess'] ?? true,
      distanceToTar: map['distanceToTar'],
    );
  }
}

/// Landmark accessibility from site with GPS
class LandmarkAccess {
  final String name;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final int? travelMinutes;
  final String? mode;

  const LandmarkAccess({
    required this.name,
    this.lat,
    this.lng,
    this.distanceKm,
    this.travelMinutes,
    this.mode,
  });

  LandmarkAccess copyWith({
    double? lat,
    double? lng,
    double? distanceKm,
    int? travelMinutes,
    String? mode,
  }) {
    return LandmarkAccess(
      name: name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceKm: distanceKm ?? this.distanceKm,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'lat': lat,
    'lng': lng,
    'distanceKm': distanceKm,
    'travelMinutes': travelMinutes,
    'mode': mode,
  };

  factory LandmarkAccess.fromMap(Map<String, dynamic> map) {
    return LandmarkAccess(
      name: map['name'] ?? '',
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
      distanceKm: map['distanceKm']?.toDouble(),
      travelMinutes: map['travelMinutes'],
      mode: map['mode'],
    );
  }
}

/// Step 6 — Roads, GPS site location, and landmark distances.
class ServicesStep extends StatefulWidget {
  final List<ServiceAvailability> services;
  final TextEditingController notesController;
  final ValueChanged<String> onToggleService;
  final void Function(String service, int rating) onRateService;

  // Road & access data
  final ValueNotifier<RoadAccess?> roadAccessNotifier;
  final ValueNotifier<LatLng?> siteLocationNotifier;
  final List<LandmarkAccess> landmarkAccesses;
  final void Function(String landmark, LandmarkAccess updated) onUpdateLandmark;

  const ServicesStep({
    super.key,
    required this.services,
    required this.notesController,
    required this.onToggleService,
    required this.onRateService,
    required this.roadAccessNotifier,
    required this.siteLocationNotifier,
    required this.landmarkAccesses,
    required this.onUpdateLandmark,
  });

  @override
  State<ServicesStep> createState() => _ServicesStepState();
}

class _ServicesStepState extends State<ServicesStep> {
  static const List<String> roadTypes = [
    'Tarred',
    'Gravel',
    'Dirt Track',
    'Footpath Only',
    'No Access',
  ];

  static const List<String> roadConditions = [
    'Excellent',
    'Good',
    'Fair',
    'Poor',
    'Unusable',
  ];

  static const List<String> travelModes = [
    'Walking',
    'Taxi/Minibus',
    'Private Car',
    'Bicycle',
    'Donkey Cart',
  ];

  static const List<Map<String, dynamic>> keyLandmarks = [
    {'name': 'Clinic/Hospital', 'icon': Icons.local_hospital_rounded},
    {'name': 'Primary School', 'icon': Icons.school_rounded},
    {'name': 'High School', 'icon': Icons.account_balance_rounded},
    {'name': 'Shop/Spaza', 'icon': Icons.store_rounded},
    {'name': 'Taxi Rank', 'icon': Icons.directions_bus_rounded},
    {'name': 'Police Station', 'icon': Icons.local_police_rounded},
  ];

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
    ],
    'Community': [
      {'name': 'Street Lights', 'icon': Icons.lightbulb_rounded},
    ],
  };

  bool _locating = false;
  String? _locationError;
  final MapController _mapController = MapController();

  ServiceAvailability? _getService(String name) {
    try {
      return widget.services.firstWhere((s) => s.name == name);
    } catch (_) {
      return null;
    }
  }

  LandmarkAccess? _getLandmark(String name) {
    try {
      return widget.landmarkAccesses.firstWhere((l) => l.name == name);
    } catch (_) {
      return null;
    }
  }

  // FIX: Complete permission flow
  Future<void> _getSiteLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      // 1. Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Enable in settings.');
      }

      // 2. Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions permanently denied. Enable in app settings.',
        );
      }

      // 3. Get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).timeout(const Duration(seconds: 15));

      final newLocation = LatLng(pos.latitude, pos.longitude);
      widget.siteLocationNotifier.value = newLocation;

      // Move map to new location
      _mapController.move(newLocation, 15);

      // Recalculate all landmark distances
      _recalculateAllDistances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(
        () => _locationError = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _recalculateAllDistances() {
    final site = widget.siteLocationNotifier.value;
    if (site == null) return;

    for (final landmark in widget.landmarkAccesses) {
      if (landmark.lat != null && landmark.lng != null) {
        final dist = Geolocator.distanceBetween(
          site.latitude,
          site.longitude,
          landmark.lat!,
          landmark.lng!,
        );
        final distKm = dist / 1000;
        final mode = landmark.mode ?? 'Walking';
        final minutes = _estimateMinutes(distKm, mode);

        widget.onUpdateLandmark(
          landmark.name,
          landmark.copyWith(
            distanceKm: double.parse(distKm.toStringAsFixed(2)),
            travelMinutes: minutes,
          ),
        );
      }
    }
  }

  int _estimateMinutes(double km, String mode) {
    final speeds = {
      'Walking': 5.0,
      'Bicycle': 15.0,
      'Donkey Cart': 8.0,
      'Taxi/Minibus': 40.0,
      'Private Car': 60.0,
    };
    final speed = speeds[mode] ?? 5.0;
    return ((km / speed) * 60).round();
  }

  Future<void> _setLandmarkLocation(String landmarkName) async {
    final currentAccess = _getLandmark(landmarkName);
    final TextEditingController latCtrl = TextEditingController(
      text: currentAccess?.lat?.toString() ?? '',
    );
    final TextEditingController lngCtrl = TextEditingController(
      text: currentAccess?.lng?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Set Location: $landmarkName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngCtrl,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.high,
                    ),
                  );
                  latCtrl.text = pos.latitude.toStringAsFixed(6);
                  lngCtrl.text = pos.longitude.toStringAsFixed(6);
                } catch (e) {
                  ScaffoldMessenger.of(
                    // ignore: use_build_context_synchronously
                    context,
                  ).showSnackBar(SnackBar(content: Text('GPS error: $e')));
                }
              },
              icon: const Icon(Icons.gps_fixed),
              label: const Text('Use Current Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final lat = double.tryParse(latCtrl.text);
      final lng = double.tryParse(lngCtrl.text);

      if (lat != null && lng != null) {
        final site = widget.siteLocationNotifier.value;
        double? distKm;
        int? minutes;

        if (site != null) {
          final dist = Geolocator.distanceBetween(
            site.latitude,
            site.longitude,
            lat,
            lng,
          );
          distKm = double.parse((dist / 1000).toStringAsFixed(2));
          final mode = currentAccess?.mode ?? 'Walking';
          minutes = _estimateMinutes(distKm, mode);
        }

        widget.onUpdateLandmark(
          landmarkName,
          (currentAccess ?? LandmarkAccess(name: landmarkName)).copyWith(
            lat: lat,
            lng: lng,
            distanceKm: distKm,
            travelMinutes: minutes,
          ),
        );
      }
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
            _buildSiteLocationSection(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildRoadAccessSection(isTablet),
            SizedBox(height: isTablet ? 28 : 20),
            _buildLandmarkAccessSection(isTablet),
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
          'Roads & Site Access',
          style: TextStyle(
            fontSize: isTablet ? 32 : 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture GPS location, road conditions, and distance to key landmarks from this site.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 15 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSiteLocationSection(bool isTablet) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: widget.siteLocationNotifier,
      builder: (context, site, _) {
        return _section(
          title: 'Site GPS Location',
          icon: Icons.my_location_rounded,
          isTablet: isTablet,
          children: [
            if (site != null) ...[
              Container(
                height: 200,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: site, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.georura.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: site,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        ...widget.landmarkAccesses
                            .where((l) => l.lat != null && l.lng != null)
                            .map(
                              (l) => Marker(
                                point: LatLng(l.lat!, l.lng!),
                                width: 30,
                                height: 30,
                                child: const Icon(
                                  Icons.place,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lat: ${site.latitude.toStringAsFixed(6)}, Lng: ${site.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _locating ? null : _getSiteLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.gps_fixed_rounded),
              label: Text(
                site == null ? 'Capture Site Location' : 'Update Location',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRoadAccessSection(bool isTablet) {
    return ValueListenableBuilder<RoadAccess?>(
      valueListenable: widget.roadAccessNotifier,
      builder: (context, roadAccess, _) {
        return _section(
          title: 'Main Road Access to Site',
          icon: Icons.add_road_rounded,
          isTablet: isTablet,
          children: [
            DropdownButtonFormField<String>(
              value: roadAccess?.roadType,
              decoration: _decoration(
                'Road Type to Site',
                icon: Icons.alt_route_rounded,
              ).copyWith(helperText: 'Primary access road type'),
              items: roadTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (v) => widget.roadAccessNotifier.value =
                  (roadAccess ??
                          const RoadAccess(
                            roadType: 'Gravel',
                            condition: 'Fair',
                            yearRoundAccess: true,
                          ))
                      .copyWith(roadType: v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: roadAccess?.condition,
              decoration: _decoration(
                'Road Condition',
                icon: Icons.construction_rounded,
              ).copyWith(helperText: 'Current state of the road'),
              items: roadConditions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => widget.roadAccessNotifier.value =
                  (roadAccess ??
                          const RoadAccess(
                            roadType: 'Gravel',
                            condition: 'Fair',
                            yearRoundAccess: true,
                          ))
                      .copyWith(condition: v),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: roadAccess?.yearRoundAccess ?? true,
              onChanged: (v) => widget.roadAccessNotifier.value =
                  (roadAccess ??
                          const RoadAccess(
                            roadType: 'Gravel',
                            condition: 'Fair',
                            yearRoundAccess: true,
                          ))
                      .copyWith(yearRoundAccess: v),
              secondary: Icon(
                roadAccess?.yearRoundAccess == false
                    ? Icons.water_damage_rounded
                    : Icons.wb_sunny_rounded,
                color: AppColors.primary,
              ),
              title: const Text(
                'Accessible During Rain/Floods',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                roadAccess?.yearRoundAccess == false
                    ? 'Road becomes impassable in bad weather'
                    : 'All-weather access',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (roadAccess?.roadType != 'Tarred' &&
                roadAccess?.roadType != null) ...[
              const SizedBox(height: 14),
              TextFormField(
                initialValue: roadAccess?.distanceToTar?.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  'Distance to Nearest Tar Road (km)',
                  icon: Icons.social_distance_rounded,
                ).copyWith(helperText: 'How far to tarred road'),
                onChanged: (v) => widget.roadAccessNotifier.value = roadAccess
                    ?.copyWith(distanceToTar: int.tryParse(v)),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLandmarkAccessSection(bool isTablet) {
    final site = widget.siteLocationNotifier.value;
    return _section(
      title: 'Distance to Key Landmarks',
      icon: Icons.place_rounded,
      isTablet: isTablet,
      children: [
        if (site == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Capture site GPS location first to auto-calculate distances',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        if (site != null) const SizedBox(height: 8),
        ...keyLandmarks.map((landmark) {
          final access = _getLandmark(landmark['name']);
          return _buildLandmarkTile(landmark, access, isTablet);
        }),
      ],
    );
  }

  Widget _buildLandmarkTile(
    Map<String, dynamic> landmark,
    LandmarkAccess? access,
    bool isTablet,
  ) {
    final name = landmark['name'] as String;
    final icon = landmark['icon'] as IconData;
    final hasCoords = access?.lat != null && access?.lng != null;
    final hasData = access?.distanceKm != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: hasData
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasData ? AppColors.primary : AppColors.divider,
          width: hasData ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
              ),
              if (hasCoords)
                IconButton(
                  icon: const Icon(Icons.edit_location_alt, size: 20),
                  onPressed: () => _setLandmarkLocation(name),
                  tooltip: 'Edit location',
                  visualDensity: VisualDensity.compact,
                ),
              if (!hasCoords)
                IconButton(
                  icon: const Icon(Icons.add_location, size: 20),
                  onPressed: () => _setLandmarkLocation(name),
                  tooltip: 'Set location',
                  visualDensity: VisualDensity.compact,
                ),
              if (hasData) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${access!.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: access?.distanceKm?.toString(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Distance (km)',
                    isDense: true,
                    suffixIcon:
                        widget.siteLocationNotifier.value != null && hasCoords
                        ? const Icon(Icons.auto_awesome, size: 16)
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) {
                    final dist = double.tryParse(v);
                    final minutes = dist != null && access?.mode != null
                        ? _estimateMinutes(dist, access!.mode!)
                        : access?.travelMinutes;
                    widget.onUpdateLandmark(
                      name,
                      (access ?? LandmarkAccess(name: name)).copyWith(
                        distanceKm: dist,
                        travelMinutes: minutes,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: access?.travelMinutes?.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Min',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (v) => widget.onUpdateLandmark(
                    name,
                    (access ?? LandmarkAccess(name: name)).copyWith(
                      travelMinutes: int.tryParse(v),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: access?.mode,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: 'Mode',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: travelModes
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final minutes = access?.distanceKm != null && v != null
                        ? _estimateMinutes(access!.distanceKm!, v)
                        : access?.travelMinutes;
                    widget.onUpdateLandmark(
                      name,
                      (access ?? LandmarkAccess(name: name)).copyWith(
                        mode: v,
                        travelMinutes: minutes,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    String category,
    List<Map<String, dynamic>> items,
    bool isTablet,
  ) {
    final availableInCat = items
        .where((i) => _getService(i['name'])?.available ?? false)
        .length;

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
          initiallyExpanded: false,
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
            '$availableInCat of ${items.length} available',
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
              onChanged: (_) => widget.onToggleService(item['name']),
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
                              widget.onRateService(item['name'], starIndex);
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
    return _section(
      title: 'Road & Access Issues',
      icon: Icons.notes_rounded,
      isTablet: isTablet,
      children: [
        TextFormField(
          controller: widget.notesController,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Bridge washouts, taxi costs, seasonal problems, security issues...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: AppColors.surfaceElevated,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isTablet) {
    final availableCount = widget.services.where((s) => s.available).length;
    final roadAccess = widget.roadAccessNotifier.value;
    final accessibleLandmarks = widget.landmarkAccesses
        .where((l) => l.distanceKm != null)
        .length;
    final avgDistance = accessibleLandmarks > 0
        ? widget.landmarkAccesses
                  .where((l) => l.distanceKm != null)
                  .map((l) => l.distanceKm!)
                  .reduce((a, b) => a + b) /
              accessibleLandmarks
        : 0.0;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Site Access Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 15 : 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow(
            'Road to Site:',
            roadAccess != null
                ? '${roadAccess.roadType} - ${roadAccess.condition}'
                : 'Not specified',
          ),
          _summaryRow(
            'Year-round Access:',
            roadAccess?.yearRoundAccess == false
                ? 'No - Seasonal issues'
                : 'Yes',
          ),
          _summaryRow(
            'Landmarks Mapped:',
            '$accessibleLandmarks of ${keyLandmarks.length}',
          ),
          if (avgDistance > 0)
            _summaryRow(
              'Avg Distance:',
              '${avgDistance.toStringAsFixed(1)} km to services',
            ),
          _summaryRow(
            'Utilities:',
            '$availableCount of ${serviceCategories.values.expand((e) => e).length} available',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
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
                  fontSize: isTablet ? 18 : 16,
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

  InputDecoration _decoration(String label, {IconData? icon, String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
