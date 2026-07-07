import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'database/db_helper.dart';
import 'models/user.dart';
import 'providers/auth_provider.dart';
import 'screens/app_shell_screen.dart';
import 'screens/login_screen.dart';
import 'screens/setup_admin_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ensure DB is ready before app starts
  await DBHelper.instance.database;

  runApp(const GeoRuraApp());
}

class GeoRuraApp extends StatelessWidget {
  const GeoRuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'GeoRura',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const StartupWrapper(),
      ),
    );
  }
}

class StartupWrapper extends StatelessWidget {
  const StartupWrapper({super.key});

  Future<bool> _hasUsers() async {
    final users = await DBHelper.instance.getAllUsers();
    return users.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasUsers(),
      builder: (context, snapshot) {
        // Still checking DB
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'GeoRura',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // No users = first install, force admin setup
        if (snapshot.data == false) {
          return const SetupAdminScreen();
        }

        // Has users, check Firebase auth state
        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoaded) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'GeoRura',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return auth.isAuthenticated
            ? const AppShellScreen()
            : const LoginScreen();
      },
    );
  }
}
