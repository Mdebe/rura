import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _highAccuracyGps = true;
  int _syncInterval = 30; // minutes

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _highAccuracyGps = prefs.getBool('highAccuracyGps') ?? true;
      _syncInterval = prefs.getInt('syncInterval') ?? 30;
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _savePref('darkMode', v);
              // TODO: Notify app theme provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restart app to apply theme')),
              );
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('High Accuracy GPS'),
            subtitle: const Text('More accurate but uses more battery'),
            value: _highAccuracyGps,
            onChanged: (v) {
              setState(() => _highAccuracyGps = v);
              _savePref('highAccuracyGps', v);
            },
            secondary: const Icon(Icons.gps_fixed),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync),
            title: const Text('Auto-sync Interval'),
            subtitle: Text('Every $_syncInterval minutes when online'),
            trailing: DropdownButton<int>(
              value: _syncInterval,
              items: [15, 30, 60, 120]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e min')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _syncInterval = v);
                  _savePref('syncInterval', v);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
