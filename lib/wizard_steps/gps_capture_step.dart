import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../theme/app_theme.dart';

class GpsCaptureStep extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final int? satellites;
  final DateTime? capturedAt;
  final TextEditingController addressController;
  final String gpsStatus;
  final bool gpsLoading;
  final String? errorMessage;
  final VoidCallback onCapture;
  final VoidCallback onOpenMap;
  final VoidCallback? onClear;

  const GpsCaptureStep({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.addressController,
    required this.gpsStatus,
    required this.gpsLoading,
    required this.onCapture,
    required this.onOpenMap,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.satellites,
    this.capturedAt,
    this.errorMessage,
    this.onClear,
  });

  Color get _qualityColor {
    if (accuracy == null) return Colors.grey;
    if (accuracy! <= 5) return Colors.green;
    if (accuracy! <= 10) return AppColors.warning;
    if (accuracy! <= 20) return Colors.orange;
    return AppColors.error;
  }

  String get _qualityText {
    if (accuracy == null) return "Waiting";
    if (accuracy! <= 5) return "Excellent";
    if (accuracy! <= 10) return "Good";
    if (accuracy! <= 20) return "Fair";
    return "Poor";
  }

  IconData get _qualityIcon {
    if (accuracy == null) return Icons.gps_off;
    if (accuracy! <= 5) return Icons.gps_fixed;
    if (accuracy! <= 10) return Icons.gps_not_fixed;
    return Icons.gps_off;
  }

  bool get _canCapture => accuracy != null && accuracy! <= 10 && !gpsLoading;

  void _copyCoords(BuildContext context) {
    if (latitude == null || longitude == null) return;
    final text = '$latitude, $longitude';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordinates copied'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? AppColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final hasError = errorMessage != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "GPS Location",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Capture accurate coordinates at the site",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (hasLocation && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.refresh),
                tooltip: 'Clear & recapture',
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Error banner
        if (hasError)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Embedded Map - NEW
        if (hasLocation)
          Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude!, longitude!),
                initialZoom: 17,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.georura',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude!, longitude!),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
                if (accuracy != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(latitude!, longitude!),
                        radius: accuracy!,
                        useRadiusInMeter: true,
                        color: _qualityColor.withValues(alpha: 0.2),
                        borderColor: _qualityColor,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
              ],
            ),
          ),

        // Live GPS Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Status row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _qualityColor.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_qualityIcon, color: _qualityColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gpsStatus,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (capturedAt != null)
                          Text(
                            timeago.format(capturedAt!),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _qualityColor.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _qualityText,
                      style: TextStyle(
                        color: _qualityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats grid
              Row(
                children: [
                  _infoTile(
                    Icons.my_location,
                    "Accuracy",
                    accuracy == null
                        ? "--"
                        : "${accuracy!.toStringAsFixed(1)} m",
                    color: _qualityColor,
                  ),
                  const SizedBox(width: 10),
                  _infoTile(
                    Icons.height,
                    "Altitude",
                    altitude == null
                        ? "--"
                        : "${altitude!.toStringAsFixed(0)} m",
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoTile(
                    Icons.speed,
                    "Speed",
                    speed == null ? "--" : "${speed!.toStringAsFixed(1)} km/h",
                  ),
                  const SizedBox(width: 10),
                  _infoTile(
                    Icons.explore,
                    "Heading",
                    heading == null ? "--" : "${heading!.toStringAsFixed(0)}°",
                  ),
                ],
              ),
              if (satellites != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _infoTile(Icons.satellite_alt, "Satellites", "$satellites"),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Captured location
        if (hasLocation)
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Location Captured",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _copyCoords(context),
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy coordinates',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _coordRow("Latitude", latitude!.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _coordRow("Longitude", longitude!.toStringAsFixed(6)),
                if (addressController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    "Address",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(addressController.text),
                ],
                if (capturedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Captured ${timeago.format(capturedAt!)}",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Capture button
        FilledButton.icon(
          onPressed: gpsLoading || !hasLocation ? null : onCapture,
          icon: gpsLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_canCapture ? Icons.gps_fixed : Icons.gps_not_fixed),
          label: Text(
            gpsLoading
                ? "Capturing..."
                : hasLocation
                ? "Recapture Location"
                : "Capture Location",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _canCapture ? AppColors.primary : Colors.grey,
          ),
        ),

        if (!_canCapture && !gpsLoading && accuracy != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Move to open area for better accuracy (need < 10m)",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),

        const SizedBox(height: 12),

        // Map button
        if (hasLocation)
          OutlinedButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open in OpenStreetMap"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
      ],
    );
  }

  Widget _coordRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
