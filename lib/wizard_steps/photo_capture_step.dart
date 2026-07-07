import 'dart:io';

import 'package:flutter/material.dart';

/// Step 3 — captures a site photo via the device camera.
class PhotoCaptureStep extends StatelessWidget {
  final String? photoPath;
  final bool photoLoading;
  final VoidCallback onCapturePhoto;

  const PhotoCaptureStep({
    super.key,
    required this.photoPath,
    required this.photoLoading,
    required this.onCapturePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Capture Site Photos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Take a clear photo of the site for the offline record.'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: photoLoading ? null : onCapturePhoto,
          icon: photoLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.camera_alt),
          label: const Text('Take Photo'),
        ),
        const SizedBox(height: 16),
        if (photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(File(photoPath!), fit: BoxFit.cover, height: 220),
          ),
      ],
    );
  }
}