import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _terms = '''
# Terms and Conditions for GeoRura

**Last updated: 7 July 2026**

## 1. Acceptance of Terms
By accessing and using the GeoRura mobile application ("App"), you agree to be bound by these Terms and Conditions. If you do not agree, do not use the App.

## 2. Purpose of the App
GeoRura is designed for field data collection of household, business, and infrastructure sites in rural KwaZulu-Natal. Data collected includes GPS coordinates, household details, photos, and service availability.

## 3. User Accounts
You are responsible for maintaining the confidentiality of your login credentials. You agree to provide accurate information when registering sites.

## 4. Data Collection and Usage
You acknowledge that data you capture will be stored locally on the device and may be synced to our secure cloud database for municipal planning and service delivery. You must obtain consent from household members before capturing personal information.

## 5. Offline Usage
The App is designed to work offline. You are responsible for syncing data when connectivity is available. We are not liable for data loss if the device is lost before syncing.

## 6. Prohibited Conduct
You agree not to:
- Submit false or misleading information
- Use the App for any unlawful purpose
- Attempt to reverse engineer or access source code
- Share your account with unauthorized persons

## 7. Termination
We reserve the right to suspend or terminate your access if you violate these terms.

## 8. Disclaimer
The App is provided "as is" without warranties. We do not guarantee accuracy of GPS, maps, or third-party data.

## 9. Limitation of Liability
GeoRura and its developers are not liable for any damages arising from use of the App, including data loss or decisions made based on collected data.

## 10. Governing Law
These terms are governed by the laws of the Republic of South Africa.

## 11. Contact
For questions: support@georura.org.za
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: Markdown(data: _terms, padding: const EdgeInsets.all(16)),
    );
  }
}
