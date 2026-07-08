import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_top_bar.dart';
import 'admin_screen.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'register_site_screen.dart';
import 'site_list_screen.dart';
import 'viewer_home.dart'; // ADD THIS

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _currentIndex = 0;
  int _refreshToken = 0;

  static const bool _enumeratorsCanRegister = true;

  Future<void> _openRegister() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSiteScreen()),
    );

    if (saved == true) {
      setState(() {
        _refreshToken += 1;
        _currentIndex = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Site saved locally.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = user.role == 'Admin';
    final isViewer = user.role == 'Viewer'; // ADD THIS
    final canRegister = isAdmin || _enumeratorsCanRegister;

    // If user is Viewer, show ViewerHome only
    if (isViewer) {
      return const ViewerHome();
    }

    final screens = <Widget>[
      DashboardScreen(
        refreshToken: _refreshToken,
        onNavigate: (index) => setState(() => _currentIndex = index),
        onOpenRegister: _openRegister,
      ), // 0: Dashboard
      const SiteListScreen(), // 1: Sites
      const SizedBox.shrink(), // 2: Register placeholder
      MapScreen(refreshToken: _refreshToken), // 3: Map
      const SizedBox.shrink(), // 4: Reports
      const ProfileScreen(), // 5: Profile
      const AdminScreen(), // 6: Admin
    ];

    if (_currentIndex >= screens.length) _currentIndex = 0;

    String getTitle() {
      switch (_currentIndex) {
        case 0:
          return 'Dashboard';
        case 1:
          return 'Sites';
        case 2:
          return 'Register';
        case 3:
          return 'Map';
        case 4:
          return 'Reports';
        case 5:
          return 'Profile';
        case 6:
          return 'Admin';
        default:
          return 'Dashboard';
      }
    }

    return Scaffold(
      appBar: RuralMapAppBar(
        title: getTitle(),
        subtitle: 'Offline-first census app',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshToken += 1),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
        isAdmin: isAdmin,
        showRegisterAction: canRegister,
        onTap: (index) => setState(() => _currentIndex = index),
        onRegisterTap: _openRegister,
      ),
    );
  }
}
