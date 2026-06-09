import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/data/kutral_ko_repository.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import 'theme.dart';

class KutralKoApp extends StatelessWidget {
  const KutralKoApp({
    super.key,
    required this.repository,
    this.requireAuthentication = true,
  });

  final KutralKoRepository repository;
  final bool requireAuthentication;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kutral Ko',
      theme: KutralKoTheme.light,
      home: requireAuthentication
          ? _AuthGate(repository: repository)
          : DashboardScreen(repository: repository, watchRemoteProfile: false),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.repository});

  final KutralKoRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const AuthScreen();
        }

        return DashboardScreen(repository: repository);
      },
    );
  }
}
