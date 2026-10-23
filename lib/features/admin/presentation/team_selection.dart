import 'package:flutter/material.dart';
import '../../teams/domain/team.dart';

class TeamSelection extends StatelessWidget {
  const TeamSelection({
    super.key,
    required this.teams,
    required this.selected,
    required this.onChanged,
  });
  final List<Team> teams;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Participating teams',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (teams.isEmpty)
        const Text(
          'Create teams from the drawer, or add them after creating the tournament.',
        ),
      Wrap(
        spacing: 8,
        children: teams
            .map(
              (team) => FilterChip(
                label: Text(team.name),
                selected: selected.contains(team.id),
                onSelected: (checked) {
                  final ids = [...selected];
                  checked ? ids.add(team.id) : ids.remove(team.id);
                  onChanged(ids);
                },
              ),
            )
            .toList(),
      ),
    ],
  );
}
