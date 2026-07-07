import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ruralmap/database/db_helper.dart';
import 'package:ruralmap/screens/setup_admin_screen.dart';
import '../providers/auth_provider.dart';
import 'app_shell_screen.dart';

import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isAuthenticated) {
      return const AppShellScreen();
    }

    return FutureBuilder<bool>(
      future: DBHelper.instance.hasUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == false) {
          return const SetupAdminScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
