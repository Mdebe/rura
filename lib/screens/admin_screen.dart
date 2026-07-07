import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _searchQuery = '';

  // Define roles here for consistency
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
    final users = await DBHelper.instance.getAllUsers();
    final sites = await DBHelper.instance.getAllSites();
    final adminCount = await DBHelper.instance.getUserCountByRole(roleAdmin);
    final enumCount = await DBHelper.instance.getUserCountByRole(
      roleEnumerator,
    );

    if (!mounted) return;
    setState(() {
      _users = users;
      _filteredUsers = users;
      _allSites = sites;
      _adminCount = adminCount;
      _enumeratorCount = enumCount;
      _loading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((u) {
          return u.name.toLowerCase().contains(query.toLowerCase()) ||
              u.email.toLowerCase().contains(query.toLowerCase()) ||
              u.phone.toLowerCase().contains(query.toLowerCase());
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
                        if (isEdit) {
                          // Update existing user - keep same UID
                          final updatedUser = user.copyWith(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            role: role,
                          );
                          await DBHelper.instance.updateUser(updatedUser);
                        } else {
                          // Create Firebase Auth user first to get UID
                          final cred = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                              );

                          await cred.user?.updateDisplayName(
                            nameCtrl.text.trim(),
                          );

                          final newUser = AppUser(
                            uid: cred.user!.uid, // ✅ Use Firebase UID
                            name: nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            role: role,
                            createdAt: DateTime.now(),
                            lastLogin: null,
                          );

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
    // Prevent deleting last admin
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
          'Delete ${user.name}? This removes local data only. Firebase user must be deleted from Console.',
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
      await DBHelper.instance.deleteUser(user.email);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted. Remove from Firebase Console too.'),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will delete ALL sites. This action cannot be undone.',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAdmin
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.2),
          child: Icon(
            isAdmin ? Icons.shield : Icons.person,
            color: isAdmin ? AppColors.error : AppColors.primary,
          ),
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
            Row(
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
                if (user.lastLogin != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Last: ${DateFormat('d MMM').format(user.lastLogin!)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) {
            if (v == 'edit') _showUserDialog(user: user);
            if (v == 'delete') _deleteUser(user);
          },
        ),
      ),
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
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty
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
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.download,
                          color: AppColors.primary,
                        ),
                        title: const Text('Export Data'),
                        subtitle: const Text('Coming soon'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Export feature coming soon'),
                            ),
                          );
                        },
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
