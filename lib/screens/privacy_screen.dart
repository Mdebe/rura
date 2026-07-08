import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: July 8, 2026\n\n'
              '1. Data We Collect\n'
              'Account: name, email, phone, role.\n'
              'Location: GPS coordinates when registering sites, if you grant permission.\n'
              'Usage: login times, device type for troubleshooting.\n\n'
              '2. How We Use Data\n'
              'To provide the service, authenticate users, sync data to cloud, and improve the app. '
              'We do not sell your data.\n\n'
              '3. Data Storage\n'
              'Data is stored in Firebase Firestore and Google Cloud. Local copies are kept on your '
              'device using SQLite for offline use. Data is encrypted in transit.\n\n'
              '4. Data Sharing\n'
              'Data is only shared with your organization admins. We do not share with third parties '
              'except Firebase/Google Cloud for hosting.\n\n'
              '5. Your Rights\n'
              'You can request access, correction, or deletion of your data by contacting your admin '
              'or support@ruralmap.app.\n\n'
              '6. Location Data\n'
              'GPS is only collected when you actively register a site. You can deny location '
              'permission, but site registration will not work.\n\n'
              '7. Security\n'
              'We use Firebase Authentication and HTTPS. However, no system is 100% secure. '
              'Keep your password safe.\n\n'
              '8. Children\n'
              'RuralMap is not intended for users under 18.\n\n'
              '9. Changes\n'
              'We will notify you of material changes via the app.\n\n'
              'Contact: privacy@ruralmap.app',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
