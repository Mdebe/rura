import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import '../models/user.dart';
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
  final String? currentUserEmail;

  const DashboardScreen({
    super.key,
    this.refreshToken = 0,
    this.onNavigate,
    this.onOpenRegister,
    this.currentUserEmail,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats _stats = DashboardStats.empty();
  List<Site> _recent = [];
  AppUser? _currentUser;
  bool _loading = true;
  bool _syncing = false;
  String? _errorMessage;
  int _pendingSync = 0;

  static const String roleAdmin = 'Admin';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken!= widget.refreshToken) {
      _load();
    }
  }

  Future<void> _bootstrap() async {
    try {
      await DBHelper.instance.database;
      await DBHelper.instance.seedIfEmpty().catchError((e, st) {
        debugPrint('Seed failed but continuing: $e\n$st');
      });
      await _load();
    } catch (error, stack) {
      debugPrint('Dashboard bootstrap failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize database: ${error.toString()}';
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
      final futures = <Future>[
        DBHelper.instance.getDashboardStats(),
        DBHelper.instance.getAllSites(limit: 4),
        DBHelper.instance.getFieldStats(),
      ];

      if (widget.currentUserEmail!= null) {
        futures.add(DBHelper.instance.getUserByEmail(widget.currentUserEmail!));
      }

      final results = await Future.wait(futures);

      if (!mounted) return;
      final fieldStats = results[2] as Map<String, int>;
      setState(() {
        _stats = results[0] as DashboardStats;
        _recent = results[1] as List<Site>;
        _pendingSync = fieldStats['pendingSync']?? 0;
        _currentUser = results.length > 3? results[3] as AppUser? : null;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error, stack) {
      debugPrint('Dashboard load failed: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load dashboard.\n${error.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _syncToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to sync')),
      );
      return;
    }

    setState(() => _syncing = true);
    try {
      final count = await SyncService().pushToFirebase();
      await _load(); // refresh pending count
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
           ? 'Synced $count sites to cloud'
            : 'All sites already synced'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _openRegister() async {
    if (widget.onOpenRegister!= null) {
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
            color: AppColors.textPrimary.withValues(alpha: 0.04),
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
    final today = DateFormat('d MMM yyyy').format(DateTime.now());
    final totalTypeCount = _stats.countsByType.values.fold<int>(0, (a, b) => a + b);
    final totalVillageCount = _stats.countsByVillage.values.fold<int>(0, (a, b) => a + b);
    final maxVillageCount = _stats.countsByVillage.values.isEmpty
       ? 1
        : _stats.countsByVillage.values.reduce((a, b) => a > b? a : b);
    final screenWidth = MediaQuery.of(context).size.width;

    final quickActionColumns = screenWidth >= 900
       ? 4
        : screenWidth >= 700
           ? 4
            : screenWidth >= 500
               ? 3
                : 2;

    final siteTypeColumns = screenWidth >= 900
       ? 6
        : screenWidth >= 700
           ? 4
            : screenWidth >= 500
               ? 4
                : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (_pendingSync > 0)
            Stack(
              children: [
                IconButton(
                  icon: _syncing
                   ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                  tooltip: 'Sync $_pendingSync pending',
                  onPressed: _syncing? null : _syncToFirebase,
                ),
                if (_pendingSync > 0 &&!_syncing)
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
            ),
          if (_currentUser?.role == roleAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () => widget.onNavigate?.call(6),
            ),
        ],
      ),
      body: _loading
         ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage!= null
             ? Center(
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
                          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
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
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Good morning, ${_currentUser?.name?? 'Enumerator'} 👋',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dashboard Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppColors.textSecondary),
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
                      const SizedBox(height: 20),

                      Container(
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
                      ),
                      const SizedBox(height: 28),

                      SectionHeader(
                        title: 'Quick Actions',
                        actionLabel: 'Customise',
                        actionIcon: Icons.tune,
                        onAction: () {},
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: quickActionColumns,
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
                              onTap: _openRegister),
                          QuickActionButton(
                              icon: Icons.search,
                              title: 'Search',
                              subtitle: 'Find Sites',
                              onTap: () => widget.onNavigate?.call(1)),
                          QuickActionButton(
                              icon: Icons.map,
                              title: 'Map View',
                              subtitle: 'View on Map',
                              onTap: () => widget.onNavigate?.call(3)),
                          QuickActionButton(
                              icon: Icons.insights,
                              title: 'Reports',
                              subtitle: 'Analytics',
                              onTap: () => widget.onNavigate?.call(4)),
                          QuickActionButton(
                              icon: Icons.cloud_upload,
                              title: 'Sync',
                              subtitle: _pendingSync > 0? '$_pendingSync pending' : 'All synced',
                              highlighted: _pendingSync > 0,
                              onTap: _syncToFirebase),
                          QuickActionButton(
                              icon: Icons.account_circle_outlined,
                              title: 'Profile',
                              subtitle: 'Enumerator',
                              onTap: () => widget.onNavigate?.call(5)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeader(
                              title: 'By Site Type',
                              actionLabel: 'View Details',
                              onAction: () {},
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: SiteType.values.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: siteTypeColumns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 165,
                              ),
                              itemBuilder: (context, index) {
                                final type = SiteType.values[index];
                                final count = _stats.countsByType[type]?? 0;
                                final pct = totalTypeCount == 0? 0.0 : (count / totalTypeCount) * 100;

                                return SiteTypeCard(
                                  type: type,
                                  count: count,
                                  percentage: pct,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      _sectionCard(
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
                      ),
                      const SizedBox(height: 28),

                      if (_stats.countsByVillage.isNotEmpty)
                        _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: 'Top Villages',
                                actionLabel: 'View All',
                                onAction: () {},
                              ),
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
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}