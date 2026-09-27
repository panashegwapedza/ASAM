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
            width: 270,
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
  const _WorkspacePage({
    required this.title,
    required this.eyebrow,
    required this.description,
  });

  final String title;
  final String eyebrow;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isAlerts = title == 'Alerts';
    final isMarketing = title == 'Marketing';
    final isIntelligence = title == 'Intelligence';

    final accent = isAlerts
        ? const Color(0xFFC45C5C)
        : isMarketing
            ? AsamTheme.gold
            : AsamTheme.navy;

    final stats = isAlerts
        ? const [('Open signals', '9'), ('Due today', '3'), ('Escalated', '1')]
        : isMarketing
            ? const [('Due today', '3'), ('Scheduled', '7'), ('Completed', '12')]
            : const [('Predictions', '9'), ('Recommendations', '6'), ('Signals', '14')];

    final actions = isAlerts
        ? const ['Review urgent signals', 'Open reorder opportunities', 'Resolve fulfilment exceptions']
        : isMarketing
            ? const ['Plan client follow-ups', 'Review campaign activity', 'Log completed contact']
            : const ['Review predictions', 'Explore recommendations', 'Inspect supporting evidence'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(eyebrow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: AsamTheme.navy)),
              const SizedBox(height: 7),
              Text(title, style: const TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(fontSize: 15, height: 1.5, color: AsamTheme.muted)),
              const SizedBox(height: 26),
              Row(
                children: stats.map((s) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: s == stats.last ? 0 : 14),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 28, height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
                            const SizedBox(height: 12),
                            Text(s.$1, style: const TextStyle(fontSize: 13, color: AsamTheme.muted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text(s.$2, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AsamTheme.ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAlerts ? 'Needs attention' : isMarketing ? 'Today’s workflow' : 'Decision workspace', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(isAlerts ? 'Signals are organised by urgency so action can happen quickly.' : isMarketing ? 'Keep client contact deliberate, visible and measurable.' : 'Use operational evidence to understand what needs attention next.', style: const TextStyle(fontSize: 14, color: AsamTheme.muted)),
                            const SizedBox(height: 12),
                            ...actions.map((action) => ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              leading: Container(width: 10, height: 10, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                              title: Text(action, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AsamTheme.muted),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wren intelligence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AsamTheme.selected, borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(isAlerts ? Icons.notifications_active_outlined : isMarketing ? Icons.campaign_outlined : Icons.auto_awesome_outlined, color: accent, size: 28),
                                  const SizedBox(height: 14),
                                  Text(isAlerts ? 'Act on signals' : isMarketing ? 'Turn insight into contact' : 'Turn history into action', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 6),
                                  const Text('The workspace will connect operational data, signals and actions as these workflows are built.', style: TextStyle(fontSize: 13, height: 1.45, color: AsamTheme.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
}
