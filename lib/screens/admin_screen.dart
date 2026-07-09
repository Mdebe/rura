import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../models/site.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  List<AppUser> _filteredUsers = [];
  List<Site> _allSites = [];
  bool _loading = true;
  int _adminCount = 0;
  int _enumeratorCount = 0;
  int _viewerCount = 0;
  String _searchQuery = '';
  String _roleFilter = 'All';

  static const String roleAdmin = 'Admin';
  static const String roleEnumerator = 'Enumerator';
  static const String roleViewer = 'Viewer';
  static const List<String> roles = [roleAdmin, roleEnumerator, roleViewer];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load from Firebase
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      final users = usersSnapshot.docs
          .map((doc) => AppUser.fromMap({...doc.data(), 'uid': doc.id}))
          .toList();

      // Sites from local DB
      final sites = await DBHelper.instance.getAllSites();

      final adminCount = users.where((u) => u.role == roleAdmin).length;
      final enumCount = users.where((u) => u.role == roleEnumerator).length;
      final viewerCount = users.where((u) => u.role == roleViewer).length;

      if (!mounted) return;
      setState(() {
        _users = users;
        _filteredUsers = users;
        _allSites = sites;
        _adminCount = adminCount;
        _enumeratorCount = enumCount;
        _viewerCount = viewerCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _filterByRole(String role) {
    setState(() {
      _roleFilter = role;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<AppUser> filtered = _users;

    // Filter by role
    if (_roleFilter != 'All') {
      filtered = filtered.where((u) => u.role == _roleFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((u) {
        return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    _filteredUsers = filtered;
  }

  Future<void> _showUserDialog({AppUser? user}) async {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final passwordCtrl = TextEditingController();
    String role = user?.role ?? roleEnumerator;
    bool creating = false;
    String? errorMsg;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit User' : 'Add User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEdit,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Min 6 characters',
                    ),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                if (isEdit && user.lastLogin != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last login: ${DateFormat('d MMM yyyy, HH:mm').format(user.lastLogin!)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (errorMsg != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: creating
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: creating
                  ? null
                  : () async {
                      if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                        setDialogState(
                          () => errorMsg = 'Name and email required',
                        );
                        return;
                      }
                      if (!isEdit && passwordCtrl.text.length < 6) {
                        setDialogState(
                          () => errorMsg = 'Password min 6 characters',
                        );
                        return;
                      }

                      setDialogState(() {
                        creating = true;
                        errorMsg = null;
                      });

                      try {
                        String uid;
                        if (!isEdit) {
                          final cred = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );
                          uid = cred.user!.uid;
                          await cred.user!.updateDisplayName(
                            nameCtrl.text.trim(),
                          );
                        } else {
                          uid = user.uid!;
                        }

                        final data = {
                          'name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'role': role,
                          'createdAt': isEdit
                              ? Timestamp.fromDate(user.createdAt)
                              : FieldValue.serverTimestamp(),
                          'lastLogin': isEdit && user.lastLogin != null
                              ? Timestamp.fromDate(user.lastLogin!)
                              : FieldValue.serverTimestamp(),
                        };

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .set(data, SetOptions(merge: true));

                        // Update local DB
                        final doc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .get();
                        final newUser = AppUser.fromMap({
                          ...doc.data()!,
                          'uid': uid,
                        });

                        if (isEdit) {
                          await DBHelper.instance.updateUser(newUser);
                        } else {
                          await DBHelper.instance.insertUser(newUser);
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } on FirebaseAuthException catch (e) {
                        setDialogState(() {
                          errorMsg = e.message ?? 'Failed to create user';
                          creating = false;
                        });
                      } catch (e) {
                        setDialogState(() {
                          errorMsg = 'Error: $e';
                          creating = false;
                        });
                      }
                    },
              child: creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) _loadData();
  }

  Future<void> _deleteUser(AppUser user) async {
    if (user.role == roleAdmin && _adminCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete last admin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${user.name}? This removes from Firebase. User must be deleted from Authentication console manually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        if (user.uid != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .delete();
        }
        await DBHelper.instance.deleteUser(user.email);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted. Remove from Auth console too.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Future<void> _changeUserRole(AppUser user, String newRole) async {
    if (user.role == roleAdmin && _adminCount <= 1 && newRole != roleAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot remove last admin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'role': newRole},
      );

      await DBHelper.instance.updateUser(user.copyWith(role: newRole));
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} role changed to $newRole')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Data'),
        content: Text(
          'This will delete ALL ${_allSites.length} sites from local database. Firebase data unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteAllSites();
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All sites deleted')));
      }
    }
  }

  Future<void> _exportToExcel() async {
    try {
      final path = await DBHelper.instance.exportSitesToExcel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: ${path.split('/').last}')),
      );
      await Share.shareXFiles([XFile(path)], text: 'GeoRura Sites Export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _exportToCsv() async {
    try {
      final path = await DBHelper.instance.exportSitesToCsv();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to CSV: ${path.split('/').last}')),
      );
      await Share.shareXFiles([XFile(path)], text: 'GeoRura Sites Export');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    final isAdmin = user.role == roleAdmin;
    final isEnum = user.role == roleEnumerator;
    // ignore: unused_local_variable
    final isViewer = user.role == roleViewer;

    Color roleColor = isAdmin
        ? AppColors.error
        : isEnum
        ? AppColors.primary
        : AppColors.info;

    IconData roleIcon = isAdmin
        ? Icons.shield
        : isEnum
        ? Icons.person
        : Icons.visibility;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.2),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(
          user.name.isEmpty ? 'No Name' : user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      fontSize: 11,
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (user.lastLogin != null)
                  Text(
                    'Last: ${DateFormat('d MMM yyyy').format(user.lastLogin!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'role_admin',
              enabled: user.role != roleAdmin,
              child: Row(
                children: [
                  Icon(
                    Icons.shield,
                    size: 18,
                    color: user.role != roleAdmin
                        ? null
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Make Admin'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'role_enum',
              enabled: user.role != roleEnumerator,
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18,
                    color: user.role != roleEnumerator
                        ? null
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Make Enumerator'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'role_viewer',
              enabled: user.role != roleViewer,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    size: 18,
                    color: user.role != roleViewer
                        ? null
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Make Viewer'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
          onSelected: (v) {
            switch (v) {
              case 'edit':
                _showUserDialog(user: user);
                break;
              case 'delete':
                _deleteUser(user);
                break;
              case 'role_admin':
                _changeUserRole(user, roleAdmin);
                break;
              case 'role_enum':
                _changeUserRole(user, roleEnumerator);
                break;
              case 'role_viewer':
                _changeUserRole(user, roleViewer);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildSiteStats() {
    final withRoadAccess = _allSites.where((s) => s.roadAccess != null).length;
    final tarredRoad = _allSites
        .where((s) => s.roadAccess?['roadType'] == 'Tarred')
        .length;
    final poorRoads = _allSites
        .where(
          (s) =>
              s.roadAccess?['condition'] == 'Poor' ||
              s.roadAccess?['condition'] == 'Unusable',
        )
        .length;
    final noYearRound = _allSites
        .where((s) => s.roadAccess?['yearRoundAccess'] == false)
        .length;

    final avgIncome = _allSites
        .where((s) => s.incomeBracket != null)
        .fold<Map<String, int>>({}, (map, s) {
          map[s.incomeBracket!] = (map[s.incomeBracket!] ?? 0) + 1;
          return map;
        });

    final totalEmployed = _allSites.fold<int>(
      0,
      // ignore: avoid_types_as_parameter_names
      (sum, s) => sum + (s.employedCount ?? 0),
    );
    final totalUnemployed = _allSites.fold<int>(
      0,
      // ignore: avoid_types_as_parameter_names
      (sum, s) => sum + (s.unemployedCount ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Site Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'With Road Data',
              withRoadAccess.toString(),
              Icons.add_road,
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Tarred Access',
              tarredRoad.toString(),
              Icons.route,
              AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Poor Roads',
              poorRoads.toString(),
              Icons.warning,
              AppColors.warning,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Seasonal Only',
              noYearRound.toString(),
              Icons.water_damage,
              AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              'Employed',
              totalEmployed.toString(),
              Icons.work,
              AppColors.success,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              'Unemployed',
              totalUnemployed.toString(),
              Icons.work_off,
              AppColors.error,
            ),
          ],
        ),
        if (avgIncome.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Income Distribution',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...avgIncome.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text(e.key)),
                  Text(
                    '${e.value} sites',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Users', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Data', icon: Icon(Icons.storage, size: 20)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _buildStatCard(
                            'Total Users',
                            _users.length.toString(),
                            Icons.people,
                            AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Enumerators',
                            _enumeratorCount.toString(),
                            Icons.person_pin,
                            AppColors.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Total Sites',
                            _allSites.length.toString(),
                            Icons.home_work,
                            AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Admins',
                            _adminCount.toString(),
                            Icons.shield,
                            AppColors.error,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Viewers',
                            _viewerCount.toString(),
                            Icons.visibility,
                            AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSiteStats(),
                    ],
                  ),
                ),
                // Users Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Manage Users',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () => _showUserDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add User'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Search users',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _filterUsers,
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: const Text('All'),
                                  selected: _roleFilter == 'All',
                                  onSelected: (_) => _filterByRole('All'),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Admin'),
                                  selected: _roleFilter == roleAdmin,
                                  onSelected: (_) => _filterByRole(roleAdmin),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Enumerator'),
                                  selected: _roleFilter == roleEnumerator,
                                  onSelected: (_) =>
                                      _filterByRole(roleEnumerator),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: const Text('Viewer'),
                                  selected: _roleFilter == roleViewer,
                                  onSelected: (_) => _filterByRole(roleViewer),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty && _roleFilter == 'All'
                                    ? 'No users yet'
                                    : 'No users found',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (_, i) =>
                                  _buildUserTile(_filteredUsers[i]),
                            ),
                    ),
                  ],
                ),
                // Data Tab
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.file_download,
                          color: AppColors.primary,
                        ),
                        title: const Text('Export to Excel'),
                        subtitle: Text(
                          'Export ${_allSites.length} sites with all fields',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _exportToExcel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.file_download,
                          color: AppColors.info,
                        ),
                        title: const Text('Export to CSV'),
                        subtitle: Text(
                          'Export ${_allSites.length} sites with all fields',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _exportToCsv,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: AppColors.error,
                        ),
                        title: const Text('Delete All Sites'),
                        subtitle: Text(
                          '${_allSites.length} sites will be permanently deleted',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _deleteAllData,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
