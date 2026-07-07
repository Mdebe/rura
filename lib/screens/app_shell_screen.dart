import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'register_site_screen.dart';
import 'reports_screen.dart';
import 'site_list_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _currentIndex = 0;
  int _refreshToken = 0;

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Sites';
      case 3:
        return 'Map';
      case 4:
        return 'Reports';
      case 5:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  String _subtitleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Search and review saved sites';
      case 3:
        return 'Offline area overview';
      case 4:
        return 'Local summaries and counts';
      case 5:
        return 'Enumerator profile';
      default:
        return 'Offline-first census app';
    }
  }

  Future<void> _openRegister() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSiteScreen()),
    );

    if (saved == true) {
      setState(() => _refreshToken += 1);
      setState(() => _currentIndex = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site saved locally.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RuralMapAppBar(
        title: _titleForIndex(_currentIndex),
        subtitle: _subtitleForIndex(_currentIndex),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshToken += 1),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: [
        DashboardScreen(
          refreshToken: _refreshToken,
          onNavigate: (index) => setState(() => _currentIndex = index),
          onOpenRegister: _openRegister,
        ),
        const SiteListScreen(),
        const SizedBox.shrink(),
        MapScreen(refreshToken: _refreshToken),
        const ReportsScreen(),
        const ProfileScreen(),
      ]),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _openRegister();
            return;
          }
          setState(() => _currentIndex = index);
        },
        onRegisterTap: _openRegister,
      ),
    );
  }

}
