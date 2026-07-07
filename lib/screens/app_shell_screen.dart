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
import 'reports_screen.dart';
import 'site_list_screen.dart';

enum AppTab { dashboard, sites, register, map, reports, admin, profile }

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  AppTab _currentTab = AppTab.dashboard;
  int _refreshToken = 0;

  List<AppTab> _tabsForRole(bool isAdmin) {
    return [
      AppTab.dashboard,
      AppTab.sites,
      AppTab.register,
      AppTab.map,
      AppTab.reports,
      if (isAdmin) AppTab.admin,
      AppTab.profile,
    ];
  }

  String _titleForTab(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return 'Dashboard';
      case AppTab.sites:
        return 'Sites';
      case AppTab.map:
        return 'Map';
      case AppTab.reports:
        return 'Reports';
      case AppTab.admin:
        return 'Admin';
      case AppTab.profile:
        return 'Profile';
      case AppTab.register:
        return 'Dashboard';
    }
  }

  String _subtitleForTab(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return 'Offline-first census app';
      case AppTab.sites:
        return 'Search and review saved sites';
      case AppTab.map:
        return 'Offline area overview';
      case AppTab.reports:
        return 'Local summaries and counts';
      case AppTab.admin:
        return 'Manage users and system';
      case AppTab.profile:
        return 'Enumerator profile';
      case AppTab.register:
        return 'Offline-first census app';
    }
  }

  Widget _screenForTab(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return DashboardScreen(
          refreshToken: _refreshToken,
          onNavigate: (index) {
            final tabs = _tabsForRole(_isAdmin);
            if (index < tabs.length) setState(() => _currentTab = tabs[index]);
          },
          onOpenRegister: _openRegister,
        );
      case AppTab.sites:
        return const SiteListScreen();
      case AppTab.map:
        return MapScreen(refreshToken: _refreshToken);
      case AppTab.reports:
        return const ReportsScreen();
      case AppTab.admin:
        return const AdminScreen();
      case AppTab.profile:
        return const ProfileScreen();
      case AppTab.register:
        return const SizedBox.shrink(); // Never shown
    }
  }

  bool get _isAdmin =>
      context.read<AuthProvider>().currentUser?.role == 'Admin';

  Future<void> _openRegister() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSiteScreen()),
    );

    if (saved == true) {
      setState(() {
        _refreshToken += 1;
        _currentTab = AppTab.dashboard;
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
    final isAdmin = user?.role == 'Admin';
    final tabs = _tabsForRole(isAdmin);

    // If current tab not available for role, reset to dashboard
    if (!tabs.contains(_currentTab)) {
      _currentTab = AppTab.dashboard;
    }

    final currentIndex = tabs.indexOf(_currentTab);

    return Scaffold(
      appBar: RuralMapAppBar(
        title: _titleForTab(_currentTab),
        subtitle: _subtitleForTab(_currentTab),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshToken += 1),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs.map((t) => _screenForTab(t)).toList(),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        isAdmin: isAdmin,
        onTap: (index) {
          final selectedTab = tabs[index];
          if (selectedTab == AppTab.register) {
            _openRegister();
            return;
          }
          setState(() => _currentTab = selectedTab);
        },
        onRegisterTap: _openRegister,
      ),
    );
  }
}
