import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const mainDestinations = [
  ('/', 'Home', Icons.home_outlined, Icons.home),
  ('/matches', 'Matches', Icons.scoreboard_outlined, Icons.scoreboard),
  ('/teams', 'Teams', Icons.groups_outlined, Icons.groups),
  (
    '/tournaments',
    'Tournaments',
    Icons.emoji_events_outlined,
    Icons.emoji_events,
  ),
];

class AppNavigation extends StatelessWidget {
  const AppNavigation({super.key, required this.path});
  final String path;
  @override
  Widget build(BuildContext context) => NavigationBar(
    indicatorColor: Theme.of(
      context,
    ).colorScheme.primary.withValues(alpha: 0.16),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => Theme.of(context).textTheme.labelMedium!.copyWith(
        color: states.contains(WidgetState.selected)
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    selectedIndex: mainDestinations.indexWhere((d) => d.$1 == path),
    onDestinationSelected: (index) => context.go(mainDestinations[index].$1),
    indicatorShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    destinations: mainDestinations
        .map(
          (d) => NavigationDestination(
            icon: Icon(d.$3),
            selectedIcon: Icon(
              d.$4,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: d.$2,
          ),
        )
        .toList(),
  );
}
