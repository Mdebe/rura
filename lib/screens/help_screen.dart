import 'package:flutter/material.dart';
import 'package:ruralmap/screens/privacy_screen.dart';
import 'package:ruralmap/screens/terms_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const ExpansionTile(
            title: Text('How do I register a new site?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '1. Tap "Register" on dashboard\n2. Fill site details\n3. Capture GPS location\n4. Add photos\n5. Submit to save locally\n6. Sync when online',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Why is my data not syncing?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Check:\n• You are logged in\n• Internet connection active\n• Firebase permissions set\n• Pending count > 0\n\nTap Sync button to retry.',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('How do I export my data?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Go to Profile > Data Management > Export Sites\nChoose:\n• Excel - Best for spreadsheets\n• CSV - Universal format\n• Database - Full SQLite backup',
                ),
              ),
            ],
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Support'),
            subtitle: const Text('support@georura.co.za'),
            onTap: () => _launchUrl('mailto:support@georura.co.za'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PrivacyScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TermsScreen()));
            },
          ),
        ],
      ),
    );
  }
}
