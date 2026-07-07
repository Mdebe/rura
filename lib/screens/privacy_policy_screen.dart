import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _policy = '''
# Privacy Policy for GeoRura

**Last updated: 7 July 2026**

## 1. Information We Collect
When you use GeoRura, we collect:
- **Location Data**: GPS coordinates, altitude, accuracy of sites you register
- **Personal Data**: Names, phone numbers, household size, gender breakdown, chronic illness count
- **Photos**: Images of sites you capture
- **Device Data**: App version, device model for crash reports
- **Account Data**: Name, email, phone, role

## 2. How We Use Information
Data is used solely for:
- Municipal service delivery planning in KZN
- Infrastructure mapping and needs analysis
- Generating anonymized statistics for government
- Syncing your records across devices

We do **not** sell data or use it for marketing.

## 3. Data Storage and Security
- Data is stored locally in SQLite on your device
- When synced, data is transmitted via HTTPS to Firebase Firestore hosted in the EU
- Firebase Authentication secures your account
- Photos stored in Firebase Storage with access rules

## 4. Offline Data
The app works offline. Unsynced data remains on your device until you sync. If you uninstall the app or lose the device before syncing, data is lost.

## 5. Data Sharing
We share data only with:
- Authorized municipal officials in King Cetshwayo District
- National/provincial government departments for planning
We never share raw personal data with third parties or advertisers.

## 6. Your Rights (POPIA Compliant)
You may:
- Request access to data collected about you
- Request correction or deletion of inaccurate data
- Withdraw consent by deleting your account
Contact: privacy@georura.org.za

## 7. Permissions
The app requests:
- **Location**: To capture GPS of sites. Background location not used
- **Camera**: To take photos of sites
- **Storage**: To save database, backups, and exports
- **Internet**: To sync data to cloud

## 8. Children’s Data
We may collect data on children as part of household size. This is only for service planning. No data identifies individual children.

## 9. Data Retention
Data is retained indefinitely for planning purposes. You may request deletion of specific records.

## 10. Changes to Policy
We will notify you of material changes via the app.

## 11. Contact
Data Protection Officer: privacy@georura.org.za
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Markdown(data: _policy, padding: const EdgeInsets.all(16)),
    );
  }
}
