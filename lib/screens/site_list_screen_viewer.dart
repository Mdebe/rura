import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/site.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'registeredAt'; // registeredAt, name, village
  bool _descending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Site>> _sitesStream() {
    return _firestore
        .collection('sites')
        .orderBy(_sortBy, descending: _descending)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) {
                try {
                  return Site.fromFirestore(doc);
                } catch (e) {
                  debugPrint('Failed to parse site ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<Site>()
              .toList(),
        );
  }

  List<Site> _filterSites(List<Site> sites) {
    if (_searchQuery.isEmpty) return sites;
    final lowerQuery = _searchQuery.toLowerCase();
    return sites.where((site) {
      return site.name.toLowerCase().contains(lowerQuery) ||
          site.siteCode.toLowerCase().contains(lowerQuery) ||
          site.village.toLowerCase().contains(lowerQuery) ||
          (site.createdByName ?? '').toLowerCase().contains(lowerQuery);
    }).toList();
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // FIXED: Don't use canLaunchUrl - Android 11+ blocks it. Just try launchUrl.
  Future<void> _launchDirections(Site site) async {
    if (site.latitude == null || site.longitude == null) {
      _showSnack('No coordinates available for this site');
      return;
    }

    final lat = site.latitude!;
    final lng = site.longitude!;
    final label = Uri.encodeComponent(site.name);

    // Try these URIs in order: Google Nav -> Google Web -> geo: -> OSM
    final uris = [
      Uri.parse('google.navigation:q=$lat,$lng'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'),
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)'),
      Uri.parse('https://www.openstreetmap.org/directions?to=$lat%2C$lng'),
    ];

    for (final uri in uris) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          debugPrint('Launched directions with: $uri');
          return; // Success
        }
      } catch (e) {
        debugPrint('Failed to launch $uri: $e');
        continue; // Try next
      }
    }

    // All failed - copy coords
    await Clipboard.setData(ClipboardData(text: '$lat, $lng'));
    _showSnack('Could not open Maps. Coordinates copied to clipboard.');
  }

  void _showSiteDetails(Site site) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Site Details',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.badge, 'Site Code', site.siteCode),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.home, 'Site Name', site.name),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.location_city, 'Village', site.village),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.directions,
                'Directions',
                site.directions.isEmpty ? 'Not provided' : site.directions,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.person,
                'Created By',
                site.createdByName?.isEmpty ?? true
                    ? 'Unknown'
                    : site.createdByName!,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.calendar_today,
                'Registered',
                site.registeredAt.toLocal().toString().split(' ')[0],
              ),
              if (site.latitude != null && site.longitude != null) ...[
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: '${site.latitude}, ${site.longitude}',
                      ),
                    );
                    _showSnack('Coordinates copied');
                  },
                  child: _buildDetailRow(
                    Icons.gps_fixed,
                    'Coordinates',
                    '${site.latitude!.toStringAsFixed(6)}, ${site.longitude!.toStringAsFixed(6)}',
                    showCopy: true,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _launchDirections(site),
                      icon: const Icon(Icons.directions),
                      label: const Text('Directions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool showCopy = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showCopy)
                    const Icon(Icons.copy, size: 14, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Sort by',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),
            RadioListTile<String>(
              title: const Text('Date Registered'),
              value: 'registeredAt',
              groupValue: _sortBy,
              onChanged: (val) {
                setState(() {
                  _sortBy = val!;
                  _descending = true;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Site Name A-Z'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (val) {
                setState(() {
                  _sortBy = val!;
                  _descending = false;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Village A-Z'),
              value: 'village',
              groupValue: _sortBy,
              onChanged: (val) {
                setState(() {
                  _sortBy = val!;
                  _descending = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'All Sites',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: _showSortMenu,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'View on Map',
            onPressed: () => Navigator.pushNamed(context, '/map'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, village, or creator...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Site>>(
              stream: _sitesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Stream error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Failed to load sites',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allSites = snapshot.data ?? [];
                final filteredSites = _filterSites(allSites);

                if (filteredSites.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.inbox_outlined
                              : Icons.search_off,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No sites available'
                              : 'No sites match "$_searchQuery"',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredSites.length,
                    itemBuilder: (context, index) {
                      final site = filteredSites[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            site.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Code: ${site.siteCode}'),
                              Text('Village: ${site.village}'),
                              Text(
                                'By: ${site.createdByName?.isEmpty ?? true ? 'Unknown' : site.createdByName} • ${site.registeredAt.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.directions),
                            tooltip: 'Directions',
                            onPressed: () => _launchDirections(site),
                          ),
                          onTap: () => _showSiteDetails(site),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
