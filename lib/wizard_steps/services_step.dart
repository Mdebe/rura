import 'package:flutter/material.dart';

/// Step 6 — toggles available services/infrastructure and captures notes.
class ServicesStep extends StatelessWidget {
  final List<String> services;
  final TextEditingController notesController;
  final ValueChanged<String> onToggleService;

  const ServicesStep({
    super.key,
    required this.services,
    required this.notesController,
    required this.onToggleService,
  });

  Widget _buildCheckbox(String label, String value) {
    return CheckboxListTile(
      value: services.contains(value),
      title: Text(label),
      onChanged: (_) => onToggleService(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text('Services & Infrastructure', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Select the services available at the site.'),
        const SizedBox(height: 16),
        _buildCheckbox('Water Supply', 'Water'),
        _buildCheckbox('Electricity', 'Electricity'),
        _buildCheckbox('Sanitation', 'Sanitation'),
        const SizedBox(height: 8),
        TextFormField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}