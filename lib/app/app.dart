import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import '../features/dashboard/presentation/dashboard_page.dart';

class AsamApp extends StatelessWidget {
  const AsamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASAM',
      debugShowCheckedModeBanner: false,
      theme: AsamTheme.light,
home: const DashboardPage(),
    );
  }
}

class AsamHomePage extends StatelessWidget {
  const AsamHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASAM'),
      ),
      body: const Center(
        child: Text(
          'Automated Sales And Marketing',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
