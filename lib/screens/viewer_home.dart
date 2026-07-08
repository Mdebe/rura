import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ViewerHome extends StatelessWidget {
  const ViewerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoRura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Welcome ${user.name}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Role: ${user.role}'),
            const SizedBox(height: 32),
            const Text('Viewer Mode: Read-only access'),
            const Text('Contact admin to upgrade permissions'),
          ],
        ),
      ),
    );
  }
}
