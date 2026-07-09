import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_selector/file_selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED for Timestamp

import '../database/db_helper.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import 'profile_edit_screen.dart';
import 'admin_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String version = "";
  Map<String, int> _stats = {
    'totalSites': 0,
    'gpsCaptured': 0,
    'pendingSync': 0,
  };
  String _dbSize = "Loading...";
  bool _loadingStats = true;
  bool _syncing = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadVersion(), _loadStats(), _loadDbSize()]);
    if (mounted) setState(() => _loadingStats = false);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => version = info.version);
  }

  // FIX: Proper Timestamp handling + fallback to local
  Future<void> _loadStats() async {
    try {
      final localStats = await DBHelper.instance.getFieldStats();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('sites')
            .where('createdByUid', isEqualTo: user.uid)
            .get();

        final totalSites = snapshot.docs.length;
        final gpsCaptured = snapshot.docs.where((doc) {
          final data = doc.data();
          return data['latitude'] != null && data['longitude'] != null;
        }).length;

        if (!mounted) return;
        setState(() {
          _stats = {
            'totalSites': totalSites,
            'gpsCaptured': gpsCaptured,
            'pendingSync': localStats['pendingSync'] ?? 0,
          };
        });
      } else {
        if (!mounted) return;
        setState(() => _stats = localStats);
      }
    } catch (e) {
      // Fallback to local stats on error
      final stats = await DBHelper.instance.getFieldStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    }
  }

  Future<void> _loadDbSize() async {
    final size = await DBHelper.instance.getDatabaseSize();
    if (!mounted) return;
    setState(() => _dbSize = size);
  }

  void _showMessage(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _syncData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in to sync', color: Colors.orange);
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) ||
        connectivity.isEmpty) {
      _showMessage('No internet connection', color: Colors.orange);
      return;
    }

    setState(() => _syncing = true);
    try {
      final count = await SyncService().fullSync();
      await _loadStats();
      if (!mounted) return;
      _showMessage(
        count > 0 ? 'Synced $count sites to cloud' : 'All sites already synced',
        color: Colors.green,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        _showMessage(
          'Permission denied. Check Firestore rules.',
          color: Colors.red,
        );
      } else {
        _showMessage('Sync failed: ${e.message}', color: Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Sync failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      _showMessage('Generating Excel file...');
      final path = await DBHelper.instance.exportSitesToExcel();
      if (!mounted) return;
      _showMessage('Excel exported to: $path');
      await Share.shareXFiles([XFile(path)], text: 'GeoRura Sites Export');
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Excel export failed: ${error.toString()}',
        color: Colors.red,
      );
    }
  }

  Future<void> _exportToCsv() async {
    try {
      _showMessage('Generating CSV file...');
      final path = await DBHelper.instance.exportSitesToCsv();
      if (!mounted) return;
      _showMessage('CSV exported to: $path');
      await Share.shareXFiles([XFile(path)], text: 'GeoRura Sites Export');
    } catch (error) {
      if (!mounted) return;
      _showMessage('CSV export failed: ${error.toString()}', color: Colors.red);
    }
  }

  Future<void> _importFromCsv() async {
    setState(() => _importing = true);
    try {
      const XTypeGroup csvTypeGroup = XTypeGroup(
        label: 'CSV',
        extensions: <String>['csv'],
        mimeTypes: <String>['text/csv'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[csvTypeGroup],
      );

      if (file == null) {
        if (!mounted) return;
        _showMessage('No file selected', color: Colors.orange);
        return;
      }

      _showMessage('Importing CSV...');
      final count = await DBHelper.instance.importSitesFromCsv(file.path);
      if (!mounted) return;
      _showMessage('Imported $count sites successfully', color: Colors.green);
      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      _showMessage('CSV import failed: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _exportDatabase() async {
    try {
      final path = await DBHelper.instance.exportDatabase();
      if (!mounted) return;
      _showMessage('Exported database to: $path');
      await Share.shareXFiles([XFile(path)], text: 'Database backup');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Export failed: ${error.toString()}', color: Colors.red);
    }
  }

  Future<void> _backupDatabase() async {
    try {
      final path = await DBHelper.instance.backupDatabase();
      if (!mounted) return;
      _showMessage('Backup saved to: $path', color: Colors.green);
      _loadDbSize();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Backup failed: ${error.toString()}', color: Colors.red);
    }
  }

  Future<void> _importDatabase() async {
    try {
      final restoredPath = await DBHelper.instance.restoreLatestBackup();
      if (restoredPath == null) {
        if (!mounted) return;
        _showMessage('No backup file found to import.', color: Colors.orange);
        return;
      }
      if (!mounted) return;
      _showMessage(
        'Database restored from backup: $restoredPath',
        color: Colors.green,
      );
      _loadAllData();
    } catch (error) {
      if (!mounted) return;
      _showMessage('Import failed: ${error.toString()}', color: Colors.red);
    }
  }

  Future<void> _showExportOptions() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export to Excel (.xlsx)'),
                subtitle: const Text('Best for opening in Excel/Google Sheets'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportToExcel();
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('Export to CSV (.csv)'),
                subtitle: const Text('Universal format, smaller file'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportToCsv();
                },
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Export Raw Database (.db)'),
                subtitle: const Text('Full SQLite file for backup'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportDatabase();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _stats['pendingSync'] ?? 0;

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.currentUser;
        final isAdmin = user?.role == 'Admin';

        return RefreshIndicator(
          onRefresh: _loadAllData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Enumerator',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user == null
                            ? 'No account details available'
                            : '${user.role} • ${user.phone}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.email,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const ProfileEditScreen(),
                                ),
                              );
                          if (!mounted) return;
                          if (updated == true) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profile"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle("Field Statistics"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home_work),
                      title: const Text("Sites Registered"),
                      trailing: _loadingStats
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "${_stats['totalSites']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text("GPS Captured"),
                      trailing: _loadingStats
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              "${_stats['gpsCaptured']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.cloud_upload,
                        color: pendingCount > 0 ? Colors.orange : Colors.green,
                      ),
                      title: const Text("Pending Sync"),
                      subtitle: Text(
                        pendingCount > 0 ? 'Tap to sync now' : 'All synced',
                      ),
                      trailing: _loadingStats
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                if (pendingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  _syncing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.sync,
                                            color: Colors.orange,
                                          ),
                                          onPressed: _syncData,
                                        ),
                                ],
                              ],
                            ),
                      onTap: pendingCount > 0 ? _syncData : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle("Data Management"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text("Sync Data"),
                      subtitle: Text(
                        pendingCount > 0
                            ? 'Upload $pendingCount unsynced records'
                            : 'All data synced',
                      ),
                      trailing: _syncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _syncing ? null : _syncData,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.download),
                      title: const Text("Export Sites"),
                      subtitle: const Text("Excel, CSV, or Database"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showExportOptions,
                    ),
                    const Divider(),
                    ListTile(
                      leading: _importing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      title: const Text("Import from CSV"),
                      subtitle: const Text("Add sites from CSV file"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _importing ? null : _importFromCsv,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.upload),
                      title: const Text("Restore Database"),
                      subtitle: const Text("Restore from latest backup"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _importDatabase,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text("Backup Database"),
                      subtitle: const Text("Create local backup copy"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _backupDatabase,
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 20),
                _sectionTitle("Admin"),
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.blue,
                    ),
                    title: const Text("Admin Dashboard"),
                    subtitle: const Text("Manage users and system settings"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionTitle("Device"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.gps_fixed),
                      title: const Text("GPS Status"),
                      subtitle: const Text("Ready"),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text("Database"),
                      subtitle: const Text("SQLite Local Storage"),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.memory),
                      title: const Text("Storage Used"),
                      subtitle: Text(_dbSize),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadDbSize,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle("Application"),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text("Settings"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text("Help & Support"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text("Privacy Policy"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text("Terms & Conditions"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TermsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text("Version"),
                      subtitle: Text(version),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  if (!mounted) return;
                  await context.read<AuthProvider>().logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
