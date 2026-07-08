import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms and Conditions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: July 8, 2026\n\n'
              '1. Acceptance of Terms\n'
              'By using RuralMap, you agree to these terms. If you do not agree, do not use the app.\n\n'
              '2. Use of Service\n'
              'RuralMap is for authorized data collection only. You must not submit false data, '
              'access accounts you do not own, or interfere with the service.\n\n'
              '3. User Accounts\n'
              'You are responsible for keeping your login credentials secure. Notify us immediately '
              'of any unauthorized access.\n\n'
              '4. Data Ownership\n'
              'Data you collect belongs to your organization. RuralMap stores it securely in Firebase '
              'and your local device.\n\n'
              '5. Offline Mode\n'
              'The app works offline. Data syncs when internet is available. You are responsible '
              'for ensuring devices sync regularly.\n\n'
              '6. Termination\n'
              'We may suspend accounts that violate these terms or submit fraudulent data.\n\n'
              '7. Limitation of Liability\n'
              'RuralMap is provided "as is". We are not liable for data loss, network failures, '
              'or decisions made using the app.\n\n'
              '8. Changes\n'
              'We may update these terms. Continued use means acceptance of changes.\n\n'
              'Contact: support@ruralmap.app',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
