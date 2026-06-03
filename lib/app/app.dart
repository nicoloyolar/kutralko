import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import 'theme.dart';

class KutralKoApp extends StatelessWidget {
  const KutralKoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kutral Ko',
      theme: KutralKoTheme.light,
      home: const DashboardScreen(),
    );
  }
}
