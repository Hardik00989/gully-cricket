import 'editor_inputs.dart';
import 'team_selection.dart';
import 'package:flutter/material.dart';
import '../../teams/domain/team.dart';
import '../../tournaments/domain/tournament.dart';
import 'date_field.dart';

class EditorFields extends StatelessWidget {
  const EditorFields({
    super.key,
    required this.kind,
    required this.values,
    required this.teams,
    required this.tournaments,
    required this.onChanged,
    this.canManage = true,
  });
  final String kind;
  final bool canManage;
  final Map<String, dynamic> values;
  final List<Team> teams;
  final List<Tournament> tournaments;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final inputs = EditorInputs(values, onChanged);
    final text = inputs.text;
    final select = inputs.select;
    final fields = <Widget>[];
    switch (kind) {
      case 'tournaments':
        fields.addAll([
          text('name', 'Tournament name'),
          text('location', 'Location'),
          select('format', 'Match format', {
            'T10': '10 overs (T10)',
            'T20': '20 overs (T20)',
            if (!['T10', 'T20'].contains(values['format']))
              values['format'] as String: values['format'] as String,
          }),
          TeamSelection(
            teams: teams,
            selected: values['teamIds'] as List<String>,
            onChanged: (ids) {
              values['teamIds'] = ids;
              onChanged();
            },
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Dates & other details'),
            subtitle: const Text('Optional - defaults to today'),
            children: [
              if (canManage)
                select('status', 'Status', {
                  'upcoming': 'Upcoming',
                  'ongoing': 'Ongoing',
                  'completed': 'Completed',
                }),
              DateField(
                label: 'Starts',
                value: values['startDate'],
                onChanged: (v) {
                  values['startDate'] = v;
                  onChanged();
                },
              ),
              DateField(
                label: 'Ends',
                value: values['endDate'],
                onChanged: (v) {
                  values['endDate'] = v;
                  onChanged();
                },
              ),
            ],
          ),
        ]);
      case 'teams':
        fields.addAll([
          text('name', 'Team name'),
          text('shortName', 'Short name (optional)', optional: true),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Tournament & logo'),
            subtitle: const Text('Optional'),
            initiallyExpanded: (values['tournamentIds'] as List).isNotEmpty,
            children: [
              text('logoUrl', 'Logo URL', optional: true),
              Text(
                'Tournaments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (tournaments.isEmpty)
                const Text('Create a tournament to add memberships.'),
              Wrap(
                spacing: 8,
                children: tournaments
                    .map(
                      (t) => FilterChip(
                        label: Text(t.name),
                        selected: (values['tournamentIds'] as List).contains(
                          t.id,
                        ),
                        onSelected: (selected) {
                          final ids = values['tournamentIds'] as List<String>;
                          if (!canManage && selected) ids.clear();
                          selected ? ids.add(t.id) : ids.remove(t.id);
                          onChanged();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ]);
      case 'players':
        fields.addAll([
          text('name', 'Player name'),
          text('jerseyNo', 'Jersey number', number: true, max: 999),
          select('role', 'Playing role', {
            'batter': 'Batter',
            'bowler': 'Bowler',
            'allrounder': 'All-rounder',
            'keeper': 'Wicketkeeper',
          }),
        ]);
      case 'matches':
        final selected = tournaments.where(
          (t) => t.id == values['tournamentId'],
        );
        final participants = selected.isEmpty
            ? <String>[]
            : selected.first.teamIds;
        final eligible = teams
            .where(
              (t) =>
                  t.tournamentIds.contains(values['tournamentId']) ||
                  participants.contains(t.id),
            )
            .toList();
        fields.addAll([
          if (tournaments.isEmpty)
            const Text(
              'Create your tournament first, then schedule its fixtures.',
            ),
          select('tournamentId', 'Tournament', {
            for (final t in tournaments) t.id: t.name,
          }),
          if (values['tournamentId'] != null && eligible.length < 2)
            const Text('Add at least two teams to this tournament first.'),
          select('teamAId', 'Team A', {for (final t in eligible) t.id: t.name}),
          select('teamBId', 'Team B', {for (final t in eligible) t.id: t.name}),
          text('venue', 'Venue'),
          text('overs', 'Overs per innings', number: true, max: 50),
          DateField(
            label: 'Match time',
            value: values['scheduledAt'],
            includeTime: true,
            onChanged: (v) {
              values['scheduledAt'] = v;
              onChanged();
            },
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Toss result'),
            subtitle: const Text(
              'Optional - you can enter this when scoring starts',
            ),
            children: [
              select('tossWinner', 'Toss winner (optional)', {
                for (final t in eligible.where(
                  (t) => [values['teamAId'], values['teamBId']].contains(t.id),
                ))
                  t.id: t.name,
              }, optional: true),
              select('tossDecision', 'Toss decision', {
                'bat': 'Bat',
                'bowl': 'Bowl',
              }),
            ],
          ),
        ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          fields[i],
        ],
      ],
    );
  }
}
