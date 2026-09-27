import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../clients/data/supabase_client_repository.dart';
import '../../orders/data/supabase_order_repository.dart';
import '../../products/data/supabase_product_repository.dart';
import '../../../app/theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final SupabaseClientRepository _clients;
  late final SupabaseProductRepository _products;
  late final SupabaseOrderRepository _orders;

  int _clientCount = 0;
  int _productCount = 0;
  int _orderCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _clients = SupabaseClientRepository(client);
    _products = SupabaseProductRepository(client);
    _orders = SupabaseOrderRepository(client);
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final results = await Future.wait([
        _clients.getClients(),
        _products.getProducts(),
        _orders.getOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _clientCount = (results[0] as List).length;
        _productCount = (results[1] as List).length;
        _orderCount = (results[2] as List).length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(compact ? 20 : 36, 32, compact ? 20 : 36, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onSearch: (_) {}, compact: compact),
                const SizedBox(height: 28),
                _Hero(onNewOrder: () => widget.onNavigate(3)),
                const SizedBox(height: 20),
                _MetricGrid(
                  compact: compact,
                  loading: _loading,
                  clientCount: _clientCount,
                  orderCount: _orderCount,
                  productCount: _productCount,
                ),
                const SizedBox(height: 20),
                compact
                    ? Column(
                        children: [
                          _AttentionCard(onViewAll: () => widget.onNavigate(1)),
                          const SizedBox(height: 20),
                          _QuickActions(onNavigate: widget.onNavigate),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _AttentionCard(onViewAll: () => widget.onNavigate(1)),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 3,
                            child: _QuickActions(onNavigate: widget.onNavigate),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                const _RecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearch, required this.compact});
  final ValueChanged<String> onSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WREN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AsamTheme.navy)),
              SizedBox(height: 6),
              Text('Good morning.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AsamTheme.ink)),
            ],
          ),
        ),
        if (!compact)
          SizedBox(
            width: 330,
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search clients, products, orders...',
                prefixIcon: Icon(Icons.search, size: 20, color: AsamTheme.muted),
              ),
            ),
          ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onNewOrder});
  final VoidCallback onNewOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 26, 26, 26),
      decoration: BoxDecoration(
        color: AsamTheme.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales and marketing intelligence.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 8),
                Text('Keep track of what was supplied, what clients need next, and where action is required.', style: TextStyle(fontSize: 14, color: Color(0xFFE3EAF0))),
              ],
            ),
          ),
          const SizedBox(width: 20),
          FilledButton(
            onPressed: null,
            child: Text('+ New Order'),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.compact, required this.loading, required this.clientCount, required this.orderCount, required this.productCount});
  final bool compact;
  final bool loading;
  final int clientCount;
  final int orderCount;
  final int productCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData('Active Clients', loading ? '—' : '$clientCount', '+8 this month'),
      _MetricData('Orders', loading ? '—' : '$orderCount', 'Operational records'),
      _MetricData('Products', loading ? '—' : '$productCount', 'Across your catalogue'),
      const _MetricData('Reorders Due', '—', 'Intelligence layer'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        mainAxisExtent: 118,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) => _MetricCard(data: cards[index]),
    );
  }
}

class _MetricData {
  const _MetricData(this.title, this.value, this.detail);
  final String title;
  final String value;
  final String detail;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.title, style: const TextStyle(fontSize: 12, color: AsamTheme.muted)),
            const Spacer(),
            Text(data.value, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700, color: AsamTheme.ink)),
            const SizedBox(height: 4),
            Text(data.detail, style: const TextStyle(fontSize: 12, color: AsamTheme.ink)),
          ],
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.onViewAll});
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Reorder opportunity', 'Client account approaching expected depletion', 'Today', Color(0xFF3A6488)),
      ('Marketing follow-up', '3 clients due for contact', '3 clients', AsamTheme.gold),
      ('Late fulfilment review', 'Order requires reason capture', 'Review', Color(0xFFC35A5A)),
      ('Stock movement', 'High-frequency product showing increased demand', '+18%', Color(0xFF3A6488)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Attention required', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
            ...items.map((item) => Column(
              children: [
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Container(width: 8, height: 8, decoration: BoxDecoration(color: item.$4, shape: BoxShape.circle)),
                  title: Text(item.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  subtitle: Text(item.$2, style: const TextStyle(fontSize: 12, color: AsamTheme.muted)),
                  trailing: Text(item.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quick actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _ActionTile(title: 'Register Product', subtitle: 'Add a product to Wren', onTap: () => onNavigate(2)),
                _ActionTile(title: 'Add Client', subtitle: 'Create a client record', onTap: () => onNavigate(2)),
                _ActionTile(title: 'Create Order', subtitle: 'Record a new order', onTap: () => onNavigate(3)),
                _ActionTile(title: 'Marketing Schedule', subtitle: 'Plan today’s follow-ups', onTap: () => onNavigate(5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F2F0),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AsamTheme.muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    const activities = [
      ('New order', 'Client order recorded', '10 min ago'),
      ('Client supplied', 'Product quantity updated', '42 min ago'),
      ('Marketing completed', 'Client contacted', 'Today'),
      ('Reorder predicted', 'Expected depletion updated', 'Today'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: Text('Recent activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                TextButton(onPressed: () {}, child: const Text('View activity')),
              ],
            ),
            ...activities.map((item) => Column(
              children: [
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AsamTheme.navy, shape: BoxShape.circle)),
                  title: Text(item.$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text(item.$2, style: const TextStyle(fontSize: 12, color: AsamTheme.muted)),
                  trailing: Text(item.$3, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
