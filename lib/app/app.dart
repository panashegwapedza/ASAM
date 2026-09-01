import 'package:flutter/material.dart';

import '../features/clients/presentation/clients_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/products/presentation/products_page.dart';
import 'theme/app_theme.dart';

class AsamApp extends StatelessWidget {
  const AsamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASAM',
      debugShowCheckedModeBanner: false,
      theme: AsamTheme.light,
      home: const AsamShell(),
    );
  }
}

class AsamShell extends StatefulWidget {
  const AsamShell({super.key});

  @override
  State<AsamShell> createState() => _AsamShellState();
}

class _AsamShellState extends State<AsamShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ProductsPage(),
    ClientsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Clients'),
        ],
      ),
    );
  }
}
