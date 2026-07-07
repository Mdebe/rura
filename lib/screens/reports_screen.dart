import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/site.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stats = await DBHelper.instance.getDashboardStats();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check),
              title: const Text('Sites Recorded'),
              trailing: Text('${_stats!.totalSites}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Registered Today'),
              trailing: Text('${_stats!.registeredToday}'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('Villages Covered'),
              trailing: Text('${_stats!.villageCount}'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Top villages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._stats!.countsByVillage.entries.map((entry) => ListTile(
                title: Text(entry.key),
                trailing: Text('${entry.value}'),
              )),
        ],
      );
  }
}
