// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Site> _sites = [];
  // ignore: unused_field
  List<Site> _allSites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  // FIX: Load from Firebase + Local and merge
  Future<void> _loadSites({String query = ''}) async {
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Load from both sources in parallel
      final results = await Future.wait([
        _loadFirebaseSites(user?.uid, query),
        DBHelper.instance.searchSites(query),
      ]);

      final firebaseSites = results[0] as List<Site>;
      final localSites = results[1] as List<Site>;

      // Merge: Firebase takes priority, deduplicate by firestoreId or siteCode
      final Map<String, Site> mergedMap = {};

      for (final site in firebaseSites) {
        final key = site.firestoreId ?? site.siteCode;
        if (key.isNotEmpty) mergedMap[key] = site;
      }

      for (final site in localSites) {
        final key = site.firestoreId ?? site.siteCode;
        if (key.isNotEmpty && !mergedMap.containsKey(key)) {
          mergedMap[key] = site;
        }
      }

      final merged = mergedMap.values.toList();
      merged.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));

      if (!mounted) return;
      setState(() {
        _allSites = merged;
        _sites = merged;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading sites: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // Load from Firebase /sites collection
  Future<List<Site>> _loadFirebaseSites(String? uid, String query) async {
    if (uid == null) return [];

    try {
      Query queryRef = _firestore
          .collection('sites')
          .where('createdByUid', isEqualTo: uid)
          .orderBy('registeredAt', descending: true);

      final snapshot = await queryRef.get();
      List<Site> sites = snapshot.docs
          .map(
            (doc) => Site.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();

      // Apply search filter locally since Firestore can't do OR queries easily
      if (query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        sites = sites.where((site) {
          return site.name.toLowerCase().contains(lowerQuery) ||
              site.village.toLowerCase().contains(lowerQuery) ||
              site.siteCode.toLowerCase().contains(lowerQuery) ||
              site.type.label.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return sites;
    } catch (e) {
      debugPrint('Firebase sites load failed: $e');
      return [];
    }
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
              hintText: 'Search by village, site name, or code',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadSites(query: '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _loadSites(query: value),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _sites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No sites found yet.'
                            : 'No sites match your search.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadSites(query: _searchController.text),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _sites.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final site = _sites[index];
                      final isSynced = site.firestoreId != null;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isSynced ? Icons.cloud_done : Icons.cloud_off,
                            color: isSynced ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${site.village} • ${site.type.label}'),
                              if (site.siteCode.isNotEmpty)
                                Text(
                                  'Code: ${site.siteCode}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${site.registeredAt.day}/${site.registeredAt.month}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: site.siteCode.isNotEmpty,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    HouseholdDetailsScreen(site: site),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
