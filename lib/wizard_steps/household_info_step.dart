import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Step 5 — collects household head, size, demographics, and contact details.
class HouseholdInfoStep extends StatelessWidget {
  final TextEditingController householdHeadController;
  final TextEditingController householdSizeController;
  final TextEditingController phoneController;
  final TextEditingController malesController;
  final TextEditingController femalesController;
  final TextEditingController pensionersController;
  final TextEditingController chronicController;

  const HouseholdInfoStep({
    super.key,
    required this.householdHeadController,
    required this.householdSizeController,
    required this.phoneController,
    required this.malesController,
    required this.femalesController,
    required this.pensionersController,
    required this.chronicController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const Text('Household Information', 
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        const Text('Capture the household head, composition, and contact information.'),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: householdHeadController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Household Head Full Name',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) 
              ? 'Required' 
              : null,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: householdSizeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Total Household Size',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.groups),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Required';
            if (int.tryParse(value) == 0) return 'Must be greater than 0';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        const Text('Household Composition', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: malesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'No. of Males',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: femalesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'No. of Females',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: pensionersController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Elders on Pension',
                  border: OutlineInputBorder(),
                  helperText: '65+ receiving grant',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: chronicController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Chronic Illness',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. diabetes, HIV',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 10) {
              return 'Enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }
}