import 'package:flutter/material.dart';
import '../../matches/domain/cricket_match.dart';
import '../../players/domain/player.dart';

class OpeningSelection {
  const OpeningSelection(
    this.striker,
    this.nonStriker,
    this.bowler,
    this.tossWinner,
    this.decision,
  );
  final String striker, nonStriker, bowler, tossWinner, decision;
}

class OpeningSheet extends StatefulWidget {
  const OpeningSheet({
    super.key,
    required this.match,
    required this.teamA,
    required this.teamB,
  });
  final CricketMatch match;
  final List<Player> teamA, teamB;
  @override
  State<OpeningSheet> createState() => _OpeningSheetState();
}

class _OpeningSheetState extends State<OpeningSheet> {
  final form = GlobalKey<FormState>();
  String? striker, nonStriker, bowler;
  late String winner, decision;
  @override
  void initState() {
    super.initState();
    final toss = Map<String, dynamic>.from(
      widget.match.data['toss'] as Map? ?? {},
    );
    winner = toss['winnerTeamId'] as String? ?? widget.match.teamAId;
    decision = toss['decision'] as String? ?? 'bat';
  }

  Widget pick(
    String label,
    String? value,
    List<Player> players,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label/$winner/$decision'),
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    isExpanded: true,
    items: players
        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
        .toList(),
    validator: (v) => v == null
        ? 'Select $label'
        : label == 'Non-striker' && v == striker
        ? 'Select a different batter'
        : null,
    onChanged: onChanged,
  );
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final second = m.innings.isNotEmpty;
    final batting = second
        ? (m.innings.first['battingTeamId'] == m.teamAId
              ? m.teamBId
              : m.teamAId)
        : decision == 'bat'
        ? winner
        : winner == m.teamAId
        ? m.teamBId
        : m.teamAId;
    final batters = batting == m.teamAId ? widget.teamA : widget.teamB;
    final bowlers = batting == m.teamAId ? widget.teamB : widget.teamA;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                second ? 'Start the chase' : 'Start match',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (!second) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: winner,
                  decoration: const InputDecoration(labelText: 'Toss winner'),
                  items: [m.teamAId, m.teamBId]
                      .map(
                        (id) => DropdownMenuItem(
                          value: id,
                          child: Text(m.teamName(id)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    winner = v!;
                    striker = null;
                    nonStriker = null;
                    bowler = null;
                  }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: decision,
                  decoration: const InputDecoration(labelText: 'Chose to'),
                  items: ['bat', 'bowl']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    decision = v!;
                    striker = null;
                    nonStriker = null;
                    bowler = null;
                  }),
                ),
              ],
              const SizedBox(height: 16),
              Text('${m.teamName(batting)} batting'),
              if (batters.length < 2 || bowlers.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Add at least two batters and one opposing bowler in Manage Teams and Players.',
                  ),
                ),
              const SizedBox(height: 16),
              pick(
                'Striker',
                striker,
                batters,
                (v) => setState(() => striker = v),
              ),
              const SizedBox(height: 16),
              pick(
                'Non-striker',
                nonStriker,
                batters,
                (v) => setState(() => nonStriker = v),
              ),
              const SizedBox(height: 16),
              pick(
                'Opening bowler',
                bowler,
                bowlers,
                (v) => setState(() => bowler = v),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (form.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      OpeningSelection(
                        striker!,
                        nonStriker!,
                        bowler!,
                        winner,
                        decision,
                      ),
                    );
                  }
                },
                child: const Text('Start innings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
