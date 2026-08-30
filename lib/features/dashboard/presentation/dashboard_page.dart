import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASAM'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Here is what needs your attention today.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),

              Text(
                'TODAY',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _MetricCard(
                    value: '7',
                    label: 'Clients needing attention',
                  ),
                  _MetricCard(
                    value: '3',
                    label: 'Likely reorders',
                  ),
                  _MetricCard(
                    value: '2',
                    label: 'Fulfilment exceptions',
                  ),
                  _MetricCard(
                    value: '5',
                    label: 'Marketing activities',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'NEEDS ATTENTION',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              const _AttentionItem(
                title: 'ABC Retail',
                detail: 'Likely reorder in 3 days',
              ),
              const _AttentionItem(
                title: 'XYZ Shop',
                detail: 'Order fulfilled late',
              ),
              const _AttentionItem(
                title: 'Delta Stores',
                detail: 'Marketing follow-up due',
              ),

              const SizedBox(height: 32),

              Text(
                'MARKETING',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              const _ProgressCard(
                title: "Today's activities",
                completed: 4,
                total: 5,
              ),

              const SizedBox(height: 24),

              Text(
                'GOALS',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              const _GoalCard(
                title: 'Monthly sales',
                progress: 0.68,
              ),

              const SizedBox(height: 32),

              Text(
                'CLIENT INTELLIGENCE',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              const _IntelligenceCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text(title),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.completed,
    required this.total,
  });

  final String title;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = completed / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('$completed of $total completed'),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.progress,
  });

  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text('${(progress * 100).round()}%'),
          ],
        ),
      ),
    );
  }
}

class _IntelligenceCard extends StatelessWidget {
  const _IntelligenceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ABC Retail',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Likely to reorder Product A soon.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Estimated remaining stock: 12 units',
            ),
          ],
        ),
      ),
    );
  }
}
