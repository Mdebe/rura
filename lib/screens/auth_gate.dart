import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // FIX: Hide Firebase's AuthProvider
import '../providers/auth_provider.dart';
import 'app_shell_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // FIX: Show loader until AuthProvider finishes initial Firebase check
    if (!auth.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.isAuthenticated) {
      return const AppShellScreen();
    }

    return const LoginScreen();
  }
}
