import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:typed_data';

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
  List<Site> _filteredSites = [];
  bool _loading = true;
  int _adminCount = 0;
  int _enumeratorCount = 0;
  String _userSearchQuery = '';
  String _selectedRoleFilter = 'All';
  final Set<String> _selectedUserEmails = {};
  Map<String, int> _sitesByUser = {};
  Map<String, int> _sitesByEnumerator = {};

  static const String roleAdmin = 'Admin';
  static const String roleEnumerator = 'Enumerator';
  static const String roleViewer = 'Viewer';
  static const List<String> roles = [roleAdmin, roleEnumerator, roleViewer];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<String> _getDbPath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'georura.db');
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final users = await DBHelper.instance.getAllUsers();
    final sites = await DBHelper.instance.getAllSites();
    final adminCount = await DBHelper.instance.getUserCountByRole(roleAdmin);
    final enumCount = await DBHelper.instance.getUserCountByRole(
      roleEnumerator,
    );
    await DBHelper.instance.getUserCountByRole(roleViewer);

    final sitesByUser = <String, int>{};
    final sitesByEnumerator = <String, int>{};

    // Use enumeratorId or userId - adjust to your Site model
    for (final s in sites) {
      final ownerId = s.name; // CHANGE THIS to match your Site model field
      // ignore: collection_methods_unrelated_type
      sitesByUser[ownerId] = (sitesByUser[ownerId] ?? 0) + 1;

      final enumUser = users.firstWhere(
        (u) => u.uid == ownerId,
        orElse: () => AppUser(
          uid: '',
          name: 'Unknown',
          email: '',
          phone: '',
          role: '',
          createdAt: DateTime.now(),
        ),
      );
      if (enumUser.name != 'Unknown') {
        sitesByEnumerator[enumUser.name] =
            (sitesByEnumerator[enumUser.name] ?? 0) + 1;
      }
    }

    if (!mounted) return;
    setState(() {
      _users = users;
      _filteredUsers = users;
      _allSites = sites;
      _filteredSites = sites;
      _adminCount = adminCount;
      _enumeratorCount = enumCount;
      _sitesByUser = sitesByUser;
      _sitesByEnumerator = sitesByEnumerator;
      _loading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _userSearchQuery = query;
      _applyUserFilters();
    });
  }

  void _applyUserFilters() {
    _filteredUsers = _users.where((u) {
      final matchesSearch =
          _userSearchQuery.isEmpty ||
          u.name.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          u.phone.toLowerCase().contains(_userSearchQuery.toLowerCase());
      final matchesRole =
          _selectedRoleFilter == 'All' || u.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _filterSites(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSites = _allSites;
      } else {
        final q = query.toLowerCase();
        _filteredSites = _allSites.where((s) {
          // ADJUST THESE TO YOUR ACTUAL Site MODEL FIELDS
          return (s.name.toLowerCase().contains(q)) ||
              (s.description?.toLowerCase().contains(q) ?? false) ||
              (s.address?.toLowerCase().contains(q) ?? false) ||
              (s.householdHead?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
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
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
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
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Created: ${DateFormat('d MMM yyyy').format(user.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (user.lastLogin != null)
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
                        if (isEdit) {
                          final updatedUser = user.copyWith(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            role: role,
                          );
                          await DBHelper.instance.updateUser(updatedUser);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .update(updatedUser.toMap());
                        } else {
                          final cred = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );
                          await cred.user?.updateDisplayName(
                            nameCtrl.text.trim(),
                          );

                          final newUser = AppUser(
                            uid: cred.user!.uid,
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            role: role,
                            createdAt: DateTime.now(),
                            lastLogin: null,
                          );
                          await DBHelper.instance.insertUser(newUser);
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(newUser.uid)
                              .set(newUser.toMap());
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
      _showSnack('Cannot delete last admin', color: AppColors.error);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Delete ${user.name}? This removes local data only. Delete from Firebase Console too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteUser(user.email);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      _loadData();
      _showSnack('User deleted');
    }
  }

  Future<void> _bulkDeleteUsers() async {
    if (_selectedUserEmails.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Users'),
        content: Text('Delete ${_selectedUserEmails.length} users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final email in _selectedUserEmails) {
        await DBHelper.instance.deleteUser(email);
      }
      _selectedUserEmails.clear();
      _loadData();
      _showSnack('Users deleted');
    }
  }

  Future<void> _resetUserPassword(AppUser user) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
      _showSnack(
        'Password reset email sent to ${user.email}',
        color: AppColors.success,
      );
    } catch (e) {
      _showSnack('Failed: $e', color: AppColors.error);
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data'),
        content: Text(
          'This will delete ALL ${_allSites.length} sites. Cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DBHelper.instance.deleteAllSites();
      _loadData();
      _showSnack('All sites deleted');
    }
  }

  Future<void> _exportUsers() async {
    try {
      final csv = StringBuffer(
        'Name,Email,Phone,Role,Created,Last Login,Sites\n',
      );
      for (final u in _users) {
        final siteCount = _sitesByUser[u.uid] ?? 0;
        csv.writeln(
          '"${u.name}","${u.email}","${u.phone}","${u.role}","${DateFormat('yyyy-MM-dd').format(u.createdAt)}","${u.lastLogin != null ? DateFormat('yyyy-MM-dd HH:mm').format(u.lastLogin!) : ''}",$siteCount',
        );
      }
      final bytes = csv.toString().codeUnits;
      final path = await _getDbPath();
      final dir = path.substring(0, path.lastIndexOf('/'));
      final file =
          '$dir/users_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      await XFile.fromData(Uint8List.fromList(bytes)).saveTo(file);
      await Share.shareXFiles([XFile(file)], text: 'GeoRura Users Export');
      _showSnack('Users exported', color: AppColors.success);
    } catch (e) {
      _showSnack('Export failed: $e', color: AppColors.error);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
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
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(AppUser user) {
    final isSelected = _selectedUserEmails.contains(user.email);
    final isAdmin = user.role == roleAdmin;
    final siteCount = _sitesByUser[user.uid] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedUserEmails.add(user.email);
                  } else {
                    _selectedUserEmails.remove(user.email);
                  }
                });
              },
            ),
            CircleAvatar(
              backgroundColor: isAdmin
                  ? AppColors.error.withValues(alpha: 0.2)
                  : AppColors.primary.withValues(alpha: 0.2),
              child: Icon(
                isAdmin ? Icons.shield : Icons.person,
                color: isAdmin ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$siteCount sites',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) {
            if (v == 'edit') _showUserDialog(user: user);
            if (v == 'reset') _resetUserPassword(user);
            if (v == 'delete') _deleteUser(user);
          },
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return RefreshIndicator(
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
                'Total Sites',
                _allSites.length.toString(),
                Icons.home_work,
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(
                'Enumerators',
                _enumeratorCount.toString(),
                Icons.person_pin,
                AppColors.info,
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
          const SizedBox(height: 20),
          _sectionTitle('Sites by Enumerator'),
          Card(
            child: SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _sitesByEnumerator.isEmpty
                    ? const Center(child: Text('No data'))
                    : PieChart(
                        PieChartData(
                          sections: _sitesByEnumerator.entries.take(5).map((e) {
                            final colors = [
                              AppColors.primary,
                              AppColors.success,
                              AppColors.warning,
                              AppColors.info,
                              AppColors.error,
                            ];
                            final idx = _sitesByEnumerator.keys
                                .toList()
                                .indexOf(e.key);
                            return PieChartSectionData(
                              value: e.value.toDouble(),
                              title: '${e.key.split(' ').first}\n${e.value}',
                              color: colors[idx % colors.length],
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_selectedUserEmails.isNotEmpty)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      onPressed: _bulkDeleteUsers,
                      icon: const Icon(Icons.delete, size: 18),
                      label: Text('Delete (${_selectedUserEmails.length})'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _showUserDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add User'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search users',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: _filterUsers,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedRoleFilter,
                    items: ['All', ...roles]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedRoleFilter = v!;
                        _applyUserFilters();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    _userSearchQuery.isEmpty
                        ? 'No users yet'
                        : 'No users found',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (_, i) => _buildUserTile(_filteredUsers[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSitesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search by plot, address, owner',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _filterSites,
          ),
        ),
        Expanded(
          child: _filteredSites.isEmpty
              ? const Center(child: Text('No sites found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredSites.length,
                  itemBuilder: (_, i) {
                    final s = _filteredSites[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.info.withValues(
                            alpha: 0.2,
                          ),
                          child: const Icon(
                            Icons.home_work,
                            color: AppColors.info,
                            size: 20,
                          ),
                        ),
                        title: Text(s.siteCode), // Use siteCode or id
                        subtitle: Text(s.address ?? 'No address'),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle("Data Management"),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.file_download,
                  color: AppColors.primary,
                ),
                title: const Text('Export Users to CSV'),
                subtitle: Text('${_users.length} users'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _exportUsers,
              ),
              const Divider(),
              ListTile(
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle("System Info"),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Database'),
                subtitle: const Text('SQLite Local Storage'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('App Version'),
                subtitle: const Text('v1.0.0'),
              ),
            ],
          ),
        ),
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
            Tab(text: 'Analytics', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'Users', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Sites', icon: Icon(Icons.home_work, size: 20)),
            Tab(text: 'System', icon: Icon(Icons.settings, size: 20)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildUsersTab(),
                _buildSitesTab(),
                _buildSystemTab(),
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
