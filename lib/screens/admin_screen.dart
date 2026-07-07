import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import '../models/site.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _users = [];
  List<Site> _allSites = [];
  bool _loading = true;
  int _adminCount = 0;
  int _enumeratorCount = 0;

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
    final enumCount = await DBHelper.instance.getUserCountByRole(roleEnumerator);

    if (!mounted) return;
    setState(() {
      _users = users;
      _allSites = sites;
      _adminCount = adminCount;
      _enumeratorCount = enumCount;
      _loading = false;
    });
  }

  Future<void> _showUserDialog({AppUser? user}) async {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    String role = user?.role ?? roleEnumerator;

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
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEdit, // Email is PK, can't edit
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                ),
                if (isEdit && user.lastLogin != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Last login: ${user.lastLogin != null ? DateFormat('d MMM yyyy, HH:mm').format(user.lastLogin!) : 'Never'}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  if (!dialogContext.mounted) return; // Fixed: use dialogContext.mounted
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Name and email required')),
                  );
                  return;
                }
                final newUser = AppUser(
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  phone: phoneCtrl.text,
                  role: role,
                  createdAt: user?.createdAt ?? DateTime.now(),
                  lastLogin: user?.lastLogin,
                );
                if (isEdit) {
                  await DBHelper.instance.updateUser(newUser);
                } else {
                  await DBHelper.instance.insertUser(newUser);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext, true); // Fixed
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true) _loadData();
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
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
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All sites deleted')),
        );
      }
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
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
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
                          _buildStatCard('Total Users', _users.length.toString(), Icons.people, AppColors.primary),
                          const SizedBox(width: 12),
                          _buildStatCard('Enumerators', _enumeratorCount.toString(), Icons.person_pin, AppColors.info),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard('Total Sites', _allSites.length.toString(), Icons.home_work, AppColors.success),
                          const SizedBox(width: 12),
                          _buildStatCard('Admins', _adminCount.toString(), Icons.shield, AppColors.error),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Manage Users',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showUserDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add User'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _users.isEmpty
                          ? const Center(child: Text('No users yet'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _users.length,
                              itemBuilder: (_, i) => _buildUserTile(_users[i]),
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
                        leading: const Icon(Icons.delete_forever, color: AppColors.error),
                        title: const Text('Delete All Sites'),
                        subtitle: Text('${_allSites.length} sites will be permanently deleted'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _deleteAllData,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.download, color: AppColors.primary),
                        title: const Text('Export Data'),
                        subtitle: const Text('Coming soon'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Export feature coming soon')),
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