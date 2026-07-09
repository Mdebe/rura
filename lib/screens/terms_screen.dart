import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.gavel_rounded,
                  size: 32,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GeoRura',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text(
              'Last updated: July 8, 2026 • Version 1.2',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Sections
            _buildSection(
              context,
              icon: Icons.check_circle_outline,
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, installing, or using GeoRura, you agree to be bound by these Terms and Conditions. If you do not agree, you must not use the app. These terms apply to all users including Enumerators, Viewers, and Administrators.',
            ),

            _buildSection(
              context,
              icon: Icons.verified_user_outlined,
              title: '2. Authorized Use & User Accounts',
              content:
                  'GeoRura is licensed for authorized rural data collection only. You must:\n\n'
                  '• Use your real identity and accurate organization details\n'
                  '• Keep login credentials secure and confidential\n'
                  '• Not share accounts or access codes\n'
                  '• Not submit false, misleading, or duplicate household data\n'
                  '• Not attempt to access data outside your assigned area\n'
                  '• Notify support@georura.app immediately of any breach\n\n'
                  'Account misuse results in immediate suspension.',
            ),

            _buildSection(
              context,
              icon: Icons.storage_rounded,
              title: '3. Data Ownership & Privacy',
              content:
                  'Data Ownership: All household, site, and survey data you collect belongs to your organization or government department. GeoRura acts as a secure data processor.\n\n'
                  'Storage: Data is stored locally on your device (SQLite) and synced to Firebase Cloud Firestore when online. We use encryption in transit and at rest.\n\n'
                  'GPS & Photos: By using the app, you consent to GPS capture and photo storage for verification. Faces should be avoided where possible.\n\n'
                  'Retention: Your organization controls data retention. GeoRura retains sync logs for 90 days for audit purposes.',
            ),

            _buildSection(
              context,
              icon: Icons.cloud_sync_rounded,
              title: '4. Offline Mode & Sync Responsibility',
              content:
                  'GeoRura works offline and queues data locally. You are responsible for:\n\n'
                  '• Syncing devices at least weekly when internet is available\n'
                  '• Not deleting the app before syncing pending records\n'
                  '• Ensuring device has sufficient storage\n\n'
                  'We are not liable for data loss if devices are lost, damaged, or wiped before sync.',
            ),

            _buildSection(
              context,
              icon: Icons.security_rounded,
              title: '5. Acceptable Use Policy',
              content:
                  'You must NOT:\n\n'
                  '• Reverse engineer, decompile, or attempt to extract source code\n'
                  '• Use automated scripts or bots to submit data\n'
                  '• Upload malicious files or malware via photo capture\n'
                  '• Interfere with Firebase backend or other users\' data\n'
                  '• Use the app for commercial purposes outside your mandate\n'
                  '• Collect data from individuals without consent\n\n'
                  'Violations may result in legal action.',
            ),

            _buildSection(
              context,
              icon: Icons.warning_amber_rounded,
              title: '6. Accuracy & Limitation of Liability',
              content:
                  'GeoRura is provided "AS IS" without warranties. We do not guarantee:\n\n'
                  '• 100% GPS accuracy - verify coordinates in the field\n'
                  '• Uninterrupted service - network/power failures may occur\n'
                  '• Data accuracy - you are responsible for verifying entries\n\n'
                  'GeoRura and its developers are NOT liable for:\n'
                  '• Decisions made based on collected data\n'
                  '• Data loss due to device failure, theft, or user error\n'
                  '• Indirect or consequential damages\n'
                  '• Government policy outcomes',
            ),

            _buildSection(
              context,
              icon: Icons.block_rounded,
              title: '7. Termination & Suspension',
              content:
                  'We reserve the right to suspend or terminate accounts that:\n\n'
                  '• Submit fraudulent or fabricated household data\n'
                  '• Violate privacy of citizens\n'
                  '• Share login credentials\n'
                  '• Breach these terms\n\n'
                  'Upon termination, you must delete the app and local data. Your organization may request data export before termination.',
            ),

            _buildSection(
              context,
              icon: Icons.update_rounded,
              title: '8. Updates & Changes to Terms',
              content:
                  'We may update GeoRura and these Terms to improve functionality or comply with law. '
                  'Material changes will be notified in-app. Continued use after updates means acceptance. '
                  'Check "Last updated" date above for version.',
            ),

            _buildSection(
              context,
              icon: Icons.balance_rounded,
              title: '9. Governing Law',
              content:
                  'These terms are governed by the laws of the Republic of South Africa. '
                  'Disputes shall be resolved in KwaZulu-Natal courts. Data protection complies with POPIA.',
            ),

            _buildSection(
              context,
              icon: Icons.contact_support_rounded,
              title: '10. Contact & Support',
              content:
                  'For questions, data requests, or to report violations:\n\n'
                  'Email: support@georura.app\n'
                  'Phone: +27 627102645\n'
                  'Hours: Mon-Fri, 08:00-17:00 SAST\n\n'
                  'For urgent data breaches: security@georura.app',
            ),

            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By using GeoRura, you acknowledge that you have read, understood, and agree to these Terms & Conditions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: Colors.green.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
