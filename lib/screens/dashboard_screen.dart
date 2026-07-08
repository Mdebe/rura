import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_registration_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/site_type_card.dart';
import '../widgets/total_sites_card.dart';
import '../widgets/village_progress_row.dart';
import 'register_site_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int refreshToken;
  final ValueChanged<int>? onNavigate;
  final VoidCallback? onOpenRegister;

  const DashboardScreen({
    super.key,
    this.refreshToken = 0,
    this.onNavigate,
    this.onOpenRegister,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  DashboardStats _stats = DashboardStats.empty();
  List<Site> _recent = [];
  AppUser? _currentUser;
  bool _loading = true;
  bool _syncing = false;
  String? _errorMessage;
  int _pendingSync = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _load();
    }
  }

  Future<void> _bootstrap() async {
    try {
      await DBHelper.instance.database;
      await _load();
    } catch (error, stack) {
      debugPrint('Dashboard bootstrap failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize database';
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Read provider before async to avoid context across async gaps
      final authUser = context.read<AuthProvider>().currentUser;

      final results = await Future.wait([
        DBHelper.instance.getDashboardStats(),
        DBHelper.instance.getAllSites(limit: 5),
        DBHelper.instance.getFieldStats(),
      ]);

      if (!mounted) return;
      final fieldStats = results[2] as Map<String, int>;

      setState(() {
        _stats = results[0] as DashboardStats;
        _recent = results[1] as List<Site>;
        _pendingSync = fieldStats['pendingSync'] ?? 0;
        _currentUser = authUser;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error, stack) {
      debugPrint('Dashboard load failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load dashboard. Pull to refresh.';
        _loading = false;
      });
    }
  }

  Future<void> _syncToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please log in to sync', isError: true);
      return;
    }

    setState(() => _syncing = true);
    try {
      final count = await SyncService().pushToFirebase();
      await _load();
      if (!mounted) return;
      _showSnack(
        count > 0 ? 'Synced $count sites to cloud' : 'All sites already synced',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Sync failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRegister() async {
    if (widget.onOpenRegister != null) {
      widget.onOpenRegister!();
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSiteScreen()),
    );
    if (saved == true) _load();
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    final totalTypeCount = _stats.countsByType.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final totalVillageCount = _stats.countsByVillage.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    final maxVillageCount = _stats.countsByVillage.values.isEmpty
        ? 1
        : _stats.countsByVillage.values.reduce((a, b) => a > b ? a : b);
    final width = MediaQuery.of(context).size.width;

    final isAdmin = _currentUser?.role == 'Admin';
    final quickActionColumns = width >= 900
        ? 4
        : width >= 700
        ? 4
        : width >= 500
        ? 3
        : 2;
    final siteTypeColumns = width >= 900
        ? 6
        : width >= 700
        ? 4
        : width >= 500
        ? 4
        : 2;

    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(today),
                  const SizedBox(height: 20),
                  _buildHeroCard(),
                  const SizedBox(height: 28),
                  _buildQuickActions(quickActionColumns, isAdmin),
                  const SizedBox(height: 28),
                  _buildSiteTypes(siteTypeColumns, totalTypeCount),
                  const SizedBox(height: 28),
                  _buildRecent(),
                  if (_stats.countsByVillage.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _buildTopVillages(totalVillageCount, maxVillageCount),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _bootstrap,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String today) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good ${_getGreeting()}, ${_currentUser?.name ?? 'Enumerator'} 👋',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildSyncButton(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    today,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return Stack(
      children: [
        IconButton(
          icon: _syncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          tooltip: _pendingSync > 0
              ? 'Sync $_pendingSync pending'
              : 'All synced',
          onPressed: _syncing ? null : _syncToFirebase,
        ),
        if (_pendingSync > 0 && !_syncing)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$_pendingSync',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: TotalSitesCard(
          total: _stats.totalSites,
          deltaToday: _stats.registeredToday,
          today: _stats.registeredToday,
          thisWeek: _stats.registeredThisWeek,
          villages: _stats.villageCount,
        ),
      ),
    );
  }

  Widget _buildQuickActions(int columns, bool isAdmin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Quick Actions',
          actionLabel: 'Customise',
          onAction: () {},
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
          children: [
            QuickActionButton(
              icon: Icons.add_circle,
              title: 'Register',
              subtitle: 'New Site',
              highlighted: true,
              onTap: _openRegister,
            ),
            QuickActionButton(
              icon: Icons.search,
              title: 'Search',
              subtitle: 'Find Sites',
              onTap: () => widget.onNavigate?.call(1),
            ),
            QuickActionButton(
              icon: Icons.map,
              title: 'Map View',
              subtitle: 'View on Map',
              onTap: () => widget.onNavigate?.call(3),
            ),
            QuickActionButton(
              icon: Icons.insights,
              title: 'Reports',
              subtitle: 'Analytics',
              onTap: () => widget.onNavigate?.call(4),
            ),
            QuickActionButton(
              icon: Icons.cloud_upload,
              title: 'Sync',
              subtitle: _pendingSync > 0
                  ? '$_pendingSync pending'
                  : 'All synced',
              highlighted: _pendingSync > 0,
              onTap: _syncToFirebase,
            ),
            QuickActionButton(
              icon: Icons.account_circle_outlined,
              title: 'Profile',
              subtitle: _currentUser?.role ?? 'Enumerator',
              onTap: () => widget.onNavigate?.call(5),
            ),
            if (isAdmin)
              QuickActionButton(
                icon: Icons.admin_panel_settings,
                title: 'Admin',
                subtitle: 'Manage Users',
                onTap: () => widget.onNavigate?.call(6),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSiteTypes(int columns, int totalTypeCount) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'By Site Type'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: SiteType.values.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 165,
            ),
            itemBuilder: (context, index) {
              final type = SiteType.values[index];
              final count = _stats.countsByType[type] ?? 0;
              final pct = totalTypeCount == 0
                  ? 0.0
                  : (count / totalTypeCount) * 100;
              return SiteTypeCard(type: type, count: count, percentage: pct);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecent() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Registrations',
            actionLabel: 'View All',
            onAction: () => widget.onNavigate?.call(1),
          ),
          const SizedBox(height: 8),
          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No sites registered yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ..._recent.map((s) => RecentRegistrationTile(site: s)),
        ],
      ),
    );
  }

  Widget _buildTopVillages(int totalVillageCount, int maxVillageCount) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Top Villages'),
          const SizedBox(height: 8),
          ..._stats.countsByVillage.entries.take(5).map((e) {
            final pct = totalVillageCount == 0
                ? 0.0
                : (e.value / totalVillageCount) * 100;
            return VillageProgressRow(
              village: e.key,
              count: e.value,
              percentage: pct,
              fraction: e.value / maxVillageCount,
            );
          }),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
