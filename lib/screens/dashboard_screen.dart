import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'dart:ui';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

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
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  DashboardStats _stats = DashboardStats.empty();
  List<Site> _recent = [];
  AppUser? _currentUser;
  bool _loading = true;
  bool _syncing = false;
  String? _errorMessage;
  int _pendingSync = 0;

  late AnimationController _headerAnimController;
  late AnimationController _cardAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _cardScale;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut),
        );

    _cardScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.elasticOut),
    );

    _bootstrap();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardAnimController.dispose();
    super.dispose();
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
      _headerAnimController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _cardAnimController.forward();
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
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _glassCard({required Widget child, double? height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
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
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea).withValues(alpha: 0.05),
              const Color(0xFF764ba2).withValues(alpha: 0.05),
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading dashboard...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
            ? _buildError()
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                  children: [
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeader(today),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScaleTransition(scale: _cardScale, child: _buildHeroCard()),
                    const SizedBox(height: 32),
                    _buildQuickActions(quickActionColumns, isAdmin),
                    const SizedBox(height: 32),
                    _buildSiteTypes(siteTypeColumns, totalTypeCount),
                    const SizedBox(height: 32),
                    _buildRecent(),
                    if (_stats.countsByVillage.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildTopVillages(totalVillageCount, maxVillageCount),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                ),
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
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ).createShader(bounds),
                    child: const Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSyncButton(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                today,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _pendingSync > 0
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_pendingSync > 0 ? Colors.orange : Colors.green).withValues(
              alpha: 0.3,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cloud_upload_outlined, color: Colors.white),
            tooltip: _pendingSync > 0
                ? 'Sync $_pendingSync pending'
                : 'All synced',
            onPressed: _syncing ? null : _syncToFirebase,
          ),
          if (_pendingSync > 0 && !_syncing)
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$_pendingSync',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
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
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _futuristicActionButton(
              icon: Icons.add_circle_rounded,
              title: 'Register',
              subtitle: 'New Site',
              gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
              onTap: _openRegister,
            ),
            _futuristicActionButton(
              icon: Icons.search_rounded,
              title: 'Search',
              subtitle: 'Find Sites',
              gradient: const [Color(0xFF56CCF2), Color(0xFF2F80ED)],
              onTap: () => widget.onNavigate?.call(1),
            ),
            _futuristicActionButton(
              icon: Icons.map_rounded,
              title: 'Map View',
              subtitle: 'View on Map',
              gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              onTap: () => widget.onNavigate?.call(3),
            ),
            _futuristicActionButton(
              icon: Icons.insights_rounded,
              title: 'Reports',
              subtitle: 'Analytics',
              gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
              onTap: () => widget.onNavigate?.call(4),
            ),
            _futuristicActionButton(
              icon: Icons.cloud_upload_rounded,
              title: 'Sync',
              subtitle: _pendingSync > 0
                  ? '$_pendingSync pending'
                  : 'All synced',
              gradient: _pendingSync > 0
                  ? [Colors.orange.shade400, Colors.orange.shade600]
                  : [Colors.green.shade400, Colors.green.shade600],
              onTap: _syncToFirebase,
            ),
            _futuristicActionButton(
              icon: Icons.account_circle_rounded,
              title: 'Profile',
              subtitle: _currentUser?.role ?? 'Enumerator',
              gradient: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
              onTap: () => widget.onNavigate?.call(5),
            ),
            if (isAdmin)
              _futuristicActionButton(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin',
                subtitle: 'Manage Users',
                gradient: const [Color(0xFFf857a6), Color(0xFFff5858)],
                onTap: () => widget.onNavigate?.call(6),
              ),
          ],
        ),
      ],
    );
  }

  Widget _futuristicActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSiteTypes(int columns, int totalTypeCount) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'By Site Type'),
            const SizedBox(height: 18),
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
      ),
    );
  }

  Widget _buildRecent() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recent Registrations',
              actionLabel: 'View All',
              onAction: () => widget.onNavigate?.call(1),
            ),
            const SizedBox(height: 12),
            if (_recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No sites registered yet.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recent.map((s) => RecentRegistrationTile(site: s)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVillages(int totalVillageCount, int maxVillageCount) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Top Villages'),
            const SizedBox(height: 12),
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
