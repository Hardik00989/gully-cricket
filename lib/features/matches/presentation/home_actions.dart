import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActions extends StatelessWidget {
  const HomeActions({super.key, required this.firstMatch});
  final bool firstMatch;
  @override
  Widget build(BuildContext context) {
    if (!firstMatch) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/create/tournaments'),
            icon: const Icon(Icons.add),
            label: const Text('New tournament'),
          ),
          OutlinedButton.icon(
            onPressed: () => context.go('/matches'),
            icon: const Icon(Icons.sports_cricket),
            label: const Text('Score a match'),
          ),
        ],
      );
    }
    final steps = [
      (
        'Create a tournament',
        'Give your competition a name and choose its teams.',
        '/create/tournaments',
      ),
      (
        'Add teams & players',
        'Build your teams and add their squads.',
        '/teams',
      ),
      (
        'Schedule a match',
        'Choose two teams, a ground and a match time.',
        '/create/matches',
      ),
      (
        'Start scoring',
        'Open a match and tap Start scoring.',
        '/matches?tab=1',
      ),
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set up your first match',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Follow these steps. You can come back at any time.'),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 16, child: Text('${i + 1}')),
                title: Text(steps[i].$1),
                subtitle: Text(steps[i].$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(steps[i].$3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
