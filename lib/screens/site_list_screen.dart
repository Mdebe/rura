import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/site.dart';
import 'household_details_screen.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Site> _sites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites({String query = ''}) async {
    setState(() => _loading = true);
    final sites = await DBHelper.instance.searchSites(query);
    setState(() {
      _sites = sites;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by village or site name',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => _loadSites(query: value),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _sites.isEmpty
                  ? const Center(child: Text('No sites found yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _sites.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final site = _sites[index];
                        return Card(
                          child: ListTile(
                            title: Text(site.name),
                            subtitle: Text('${site.village} • ${site.type.label}'),
                            trailing: Text(
                              '${site.registeredAt.day}/${site.registeredAt.month}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => HouseholdDetailsScreen(site: site),
                              ));
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
