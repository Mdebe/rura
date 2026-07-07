import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/site.dart';

/// Step 7 — final read-only summary shown before saving locally.
class ReviewStep extends StatelessWidget {
  final SiteType selectedType;
  final String name;
  final String village;
  final String address;
  final String householdHead;
  final List<String> services;
  final String? photoPath;

  const ReviewStep({
    super.key,
    required this.selectedType,
    required this.name,
    required this.village,
    required this.address,
    required this.householdHead,
    required this.services,
    required this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Everything looks ready to save locally.'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Site Type: ${selectedType.label}'),
                Text('Site Name: $name'),
                Text('Village: $village'),
                Text('Address: ${address.isEmpty ? "Not captured" : address}'),
                Text('Household Head: ${householdHead.isEmpty ? "Not captured" : householdHead}'),
                Text('Services: ${services.isEmpty ? "None" : services.join(", ")}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (photoPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(File(photoPath!), fit: BoxFit.cover, height: 220),
          ),
      ],
    );
  }
}