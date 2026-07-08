import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_rounded,
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
                        'Privacy Policy',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GeoRura complies with POPIA (Protection of Personal Information Act). We protect your data and citizen privacy.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Sections
            _buildSection(
              context,
              icon: Icons.dataset_rounded,
              title: '1. Information We Collect',
              content:
                  'Personal Information:\n'
                  '• Account: Full name, email, phone number, organization, role\n'
                  '• Authentication: Firebase UID, login timestamps\n\n'
                  'Field Data:\n'
                  '• GPS: Latitude/longitude when you capture site location\n'
                  '• Photos: Site images you capture for verification\n'
                  '• Household Data: Names, demographics, services - belongs to your organization\n'
                  '• Device: Device type, OS version, app version for troubleshooting\n\n'
                  'Technical Data:\n'
                  '• Usage logs: Login times, sync status, errors (no keystrokes)\n'
                  '• Firebase Analytics: Anonymous app performance metrics',
            ),

            _buildSection(
              context,
              icon: Icons.settings_suggest_rounded,
              title: '2. How We Use Your Information',
              content:
                  'We use collected data to:\n\n'
                  '• Provide the GeoRura service and sync data to cloud\n'
                  '• Authenticate users and enforce role-based access\n'
                  '• Display household sites on maps for your organization\n'
                  '• Generate reports for government planning\n'
                  '• Troubleshoot crashes and improve app performance\n'
                  '• Send service notifications (sync status, updates)\n\n'
                  'We DO NOT:\n'
                  '• Sell your data to third parties\n'
                  '• Use citizen data for marketing\n'
                  '• Track you outside the app\n'
                  '• Share individual household data publicly',
            ),

            _buildSection(
              context,
              icon: Icons.storage_rounded,
              title: '3. Data Storage & Security',
              content:
                  'Storage Locations:\n'
                  '• Local: SQLite database on your device for offline use\n'
                  '• Cloud: Firebase Firestore (Google Cloud, South Africa region)\n'
                  '• Photos: Firebase Storage with access controls\n\n'
                  'Security Measures:\n'
                  '• Encryption in transit: TLS/HTTPS for all sync\n'
                  '• Encryption at rest: Firebase default encryption\n'
                  '• Authentication: Firebase Auth with secure tokens\n'
                  '• Access Control: Firestore rules enforce Viewer/Enumerator/Admin roles\n\n'
                  'Retention: Data retained per your organization policy. Sync logs deleted after 90 days.',
            ),

            _buildSection(
              context,
              icon: Icons.share_rounded,
              title: '4. Data Sharing & Third Parties',
              content:
                  'We share data only with:\n\n'
                  '• Your Organization: Admins can view all sites you collect\n'
                  '• Firebase/Google Cloud: For hosting, auth, and storage (DPA in place)\n'
                  '• Government: Aggregated statistics only, no personal identifiers\n\n'
                  'We do NOT share with:\n'
                  '• Advertisers or marketing companies\n'
                  '• Data brokers\n'
                  '• Other government departments without authorization\n\n'
                  'Legal Requests: We may disclose data if required by South African law or court order.',
            ),

            _buildSection(
              context,
              icon: Icons.gps_fixed_rounded,
              title: '5. Location Data (GPS)',
              content:
                  'Purpose: GPS is captured ONLY when you tap "Capture Location" to register a site. Used to map households for service delivery.\n\n'
                  'Control: You can deny location permission, but site registration requires GPS. You can delete individual GPS points before syncing.\n\n'
                  'Accuracy: We store latitude, longitude, altitude, and accuracy radius. Not used for tracking.\n\n'
                  'Background: GeoRura does NOT track location in background. GPS only active during capture.',
            ),

            _buildSection(
              context,
              icon: Icons.photo_camera_rounded,
              title: '6. Photos & Biometric Data',
              content:
                  'Photos: Site photos you capture are stored to verify locations. Avoid capturing faces of citizens. If faces are visible, obtain verbal consent.\n\n'
                  'No Biometrics: GeoRura does NOT collect fingerprints, facial recognition, or biometric data.\n\n'
                  'Storage: Photos stored in Firebase Storage with signed URLs. Deleted when your organization purges records.',
            ),

            _buildSection(
              context,
              icon: Icons.admin_panel_settings_rounded,
              title: '7. Your Rights (POPIA)',
              content:
                  'Under POPIA, you have the right to:\n\n'
                  '• Access: Request a copy of your personal data\n'
                  '• Correction: Fix inaccurate data in your profile\n'
                  '• Deletion: Request account deletion (subject to organization policy)\n'
                  '• Object: Opt-out of non-essential data processing\n'
                  '• Complain: Lodge complaints with Information Regulator\n\n'
                  'For citizen data: Requests must go through your organization admin or privacy@georura.app. We respond within 30 days.',
            ),

            _buildSection(
              context,
              icon: Icons.child_care_rounded,
              title: '8. Children\'s Privacy',
              content:
                  'GeoRura is for government enumerators aged 18+. We do not knowingly collect data from children. '
                  'If citizen household data includes minors, it is collected by authorized officials with parental consent per local regulations.',
            ),

            _buildSection(
              context,
              icon: Icons.delete_forever_rounded,
              title: '9. Data Deletion',
              content:
                  'Your Account: Contact your admin or privacy@georura.app. Deletion removes your profile but not household data you collected (belongs to organization).\n\n'
                  'Household Data: Only your organization Admin can delete site records. Unsynced local data deleted when you uninstall app.\n\n'
                  'Backups: Deleted data removed from backups within 90 days.',
            ),

            _buildSection(
              context,
              icon: Icons.update_rounded,
              title: '10. Changes to This Policy',
              content:
                  'We may update this Privacy Policy for legal compliance or new features. '
                  'Material changes will be notified via in-app banner. Continued use after 30 days means acceptance. '
                  'Check "Last updated" date above.',
            ),

            _buildSection(
              context,
              icon: Icons.contact_support_rounded,
              title: '11. Contact Us',
              content:
                  'Data Protection Officer:\n'
                  'Email: privacy@georura.app\n'
                  'Phone: +27 (0) 31 000 0000\n\n'
                  'Security Issues: security@georura.app\n'
                  'General Support: support@georura.app\n\n'
                  'Information Regulator (South Africa):\n'
                  'Website: www.justice.gov.za/inforeg',
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
                  Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GeoRura is committed to protecting citizen privacy and complying with POPIA. Your data is secure.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade900,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
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
