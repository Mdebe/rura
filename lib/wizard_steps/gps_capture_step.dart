import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class GpsCaptureStep extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;

  final DateTime? capturedAt;

  final TextEditingController addressController;

  final String gpsStatus;
  final bool gpsLoading;

  final VoidCallback onCapture;
  final VoidCallback onOpenMap;

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
    this.capturedAt,
  });

  Color get _qualityColor {
    if (accuracy == null) return Colors.grey;

    if (accuracy! <= 5) {
      return Colors.green;
    }

    if (accuracy! <= 10) {
      return Colors.orange;
    }

    return Colors.red;
  }

  String get _qualityText {
    if (accuracy == null) return "Waiting";

    if (accuracy! <= 5) return "Excellent";

    if (accuracy! <= 10) return "Good";

    if (accuracy! <= 20) return "Fair";

    return "Poor";
  }

  Widget _infoTile(
      IconData icon,
      String title,
      String value,
      ) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 10,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          "Live GPS Location",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          "Move closer to the site and wait until GPS accuracy is acceptable before capturing.",
        ),

        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _qualityColor.withValues(alpha: .15),
                      child: Icon(
                        Icons.gps_fixed,
                        color: _qualityColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        gpsStatus,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(_qualityText),
                      backgroundColor: _qualityColor.withValues(alpha: .15),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _infoTile(
                      Icons.my_location,
                      "Accuracy",
                      accuracy == null
                          ? "--"
                          : "${accuracy!.toStringAsFixed(1)} m",
                    ),
                    _infoTile(
                      Icons.height,
                      "Altitude",
                      altitude == null
                          ? "--"
                          : "${altitude!.toStringAsFixed(0)} m",
                    ),
                  ],
                ),
                Row(
                  children: [
                    _infoTile(
                      Icons.speed,
                      "Speed",
                      speed == null
                          ? "--"
                          : "${speed!.toStringAsFixed(1)} km/h",
                    ),
                    _infoTile(
                      Icons.explore,
                      "Heading",
                      heading == null
                          ? "--"
                          : "${heading!.toStringAsFixed(0)}°",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (latitude != null)
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Captured Location",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Divider(),
                  SelectableText("Latitude\n$latitude"),
                  const SizedBox(height: 10),
                  SelectableText("Longitude\n$longitude"),
                  const SizedBox(height: 14),
                  Text(addressController.text),
                  if (capturedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Captured: ${capturedAt!.toLocal()}",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        const SizedBox(height: 24),

        ElevatedButton.icon(
          onPressed: gpsLoading ? null : onCapture,
          icon: gpsLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.gps_fixed),
          label: Text(
            gpsLoading
                ? "Capturing Location..."
                : "Refresh Live GPS",
          ),
        ),

        const SizedBox(height: 12),

        if (latitude != null)
          OutlinedButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map),
            label: const Text("Open in OpenStreetMap"),
          ),
      ],
    );
  }
}