import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/presentation/auth_page.dart';
import '../features/clients/presentation/clients_page.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/products/presentation/products_page.dart';
import 'theme/app_theme.dart';

class AsamApp extends StatelessWidget {
  const AsamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wren',
      debugShowCheckedModeBanner: false,
      theme: AsamTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        if (user == null) return const AuthPage();
        if (user.isAnonymous) return const AuthPage(isAnonymous: true);
        return const AsamShell();
      },
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

  final List<String> _labels = const [
    'Dashboard',
    'Alerts',
    'Products',
    'Clients',
    'Orders',
    'Marketing',
    'Intelligence',
  ];

  final List<IconData> _icons = const [
    Icons.dashboard_outlined,
    Icons.notifications_none_outlined,
    Icons.inventory_2_outlined,
    Icons.people_outline,
    Icons.shopping_bag_outlined,
    Icons.campaign_outlined,
    Icons.auto_awesome_outlined,
  ];

  late final List<Widget> _pages = [
    DashboardPage(onNavigate: _navigate),
    const _WorkspacePage(title: 'Alerts', eyebrow: 'ACTION QUEUE', description: 'Review the signals that need attention and turn them into work.'),
    const ProductsPage(),
    const ClientsPage(),
    const OrdersPage(),
    const _WorkspacePage(title: 'Marketing', eyebrow: 'CLIENT CONTACT', description: 'Plan, execute and learn from client follow-ups.'),
    const _WorkspacePage(title: 'Intelligence', eyebrow: 'DECISION SUPPORT', description: 'Turn operational history into predictions, recommendations and next actions.'),
  ];

  void _navigate(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;

    if (!desktop) {
      return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: _Sidebar(
              selectedIndex: _selectedIndex,
              labels: _labels,
              icons: _icons,
              onSelected: (index) {
                Navigator.pop(context);
                _navigate(index);
              },
            ),
          ),
        ),
        appBar: AppBar(
          title: const Text('wren', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1)),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 256,
            child: _Sidebar(
              selectedIndex: _selectedIndex,
              labels: _labels,
              icons: _icons,
              onSelected: _navigate,
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selectedIndex, required this.labels, required this.icons, required this.onSelected});
  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: AsamTheme.navy, letterSpacing: -1.5),
                  children: [
                    TextSpan(text: 'wren'),
                    TextSpan(text: '•', style: TextStyle(color: AsamTheme.gold, fontSize: 18)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('WORKSPACE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: AsamTheme.muted)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: labels.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: ListTile(
                    selected: selectedIndex == index,
                    selectedTileColor: AsamTheme.selected,
                    selectedColor: AsamTheme.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: Icon(icons[index], size: 21, color: selectedIndex == index ? AsamTheme.navy : AsamTheme.muted),
                    title: Text(labels[index], style: TextStyle(fontSize: 16, fontWeight: selectedIndex == index ? FontWeight.w800 : FontWeight.w600, color: selectedIndex == index ? AsamTheme.navy : AsamTheme.muted)),
                    onTap: () => onSelected(index),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  ),
                ),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 2),
              child: Text('Sales Manager', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AsamTheme.ink)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Wren workspace', style: TextStyle(fontSize: 13, color: AsamTheme.muted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspacePage extends StatelessWidget {
  const _WorkspacePage({required this.title, required this.eyebrow, required this.description});
  final String title;
  final String eyebrow;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: AsamTheme.navy)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: AsamTheme.muted)),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AsamTheme.selected, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.construction_outlined, color: AsamTheme.navy),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text('This workspace is now part of the Wren navigation foundation. Its workflows will be built on the same visual language and Supabase data model.'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
