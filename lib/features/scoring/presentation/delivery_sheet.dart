import 'package:flutter/material.dart';
import '../../players/domain/player.dart';
import '../domain/scoring_engine.dart';

class DeliverySheet extends StatefulWidget {
  const DeliverySheet({
    super.key,
    required this.state,
    required this.players,
    required this.maxOvers,
    this.target,
    this.extra = ExtraType.none,
    this.wicket = false,
  });
  final InningsState state;
  final List<Player> players;
  final int maxOvers;
  final int? target;
  final ExtraType extra;
  final bool wicket;
  @override
  State<DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<DeliverySheet> {
  late ExtraType extra;
  late String dismissed;
  String wicketType = 'bowled';
  String? nextBatter, error;
  int runs = 0, extras = 1;
  @override
  void initState() {
    super.initState();
    extra = widget.extra;
    dismissed = widget.state.strikerId;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.players
        .where(
          (p) =>
              !widget.state.dismissed.contains(p.id) &&
              ![
                widget.state.strikerId,
                widget.state.nonStrikerId,
              ].contains(p.id),
        )
        .toList();
    Widget number(
      String label,
      int current,
      ValueChanged<int> change, {
      int min = 0,
    }) => DropdownButtonFormField<int>(
      initialValue: current,
      decoration: InputDecoration(labelText: label),
      items: List.generate(
        7 - min,
        (i) => DropdownMenuItem(value: i + min, child: Text('${i + min}')),
      ),
      onChanged: (v) => setState(() => change(v!)),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.wicket ? 'Record wicket' : 'Record extras',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExtraType>(
              initialValue: extra,
              decoration: const InputDecoration(labelText: 'Delivery type'),
              items: ExtraType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(switch (e) {
                        ExtraType.none => 'Normal ball',
                        ExtraType.noball => 'No ball',
                        ExtraType.legbye => 'Leg bye',
                        ExtraType.bye => 'Bye',
                        ExtraType.wide => 'Wide',
                      }),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                extra = v!;
                runs = 0;
              }),
            ),
            const SizedBox(height: 16),
            if ([ExtraType.none, ExtraType.noball].contains(extra))
              number('Runs off bat', runs, (v) => runs = v),
            if (extra != ExtraType.none) ...[
              const SizedBox(height: 16),
              number(
                ['wide', 'noball'].contains(extra.name)
                    ? 'Extra runs (including 1 penalty)'
                    : 'Extra runs',
                extras,
                (v) => extras = v,
                min: 1,
              ),
            ],
            if (widget.wicket) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: wicketType,
                decoration: const InputDecoration(labelText: 'Dismissal'),
                items:
                    [
                          'bowled',
                          'caught',
                          'lbw',
                          'stumped',
                          'run out',
                          'hit wicket',
                          'obstructing the field',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => wicketType = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: dismissed,
                decoration: const InputDecoration(
                  labelText: 'Dismissed batter',
                ),
                items: widget.players
                    .where(
                      (p) => [
                        widget.state.strikerId,
                        widget.state.nonStrikerId,
                      ].contains(p.id),
                    )
                    .map(
                      (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => dismissed = v!),
              ),
              if (widget.state.wickets < 9) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextBatter,
                  decoration: const InputDecoration(labelText: 'Next batter'),
                  items: available
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => nextBatter = v),
                ),
              ],
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final delivery = Delivery(
                  runsOffBat: [ExtraType.none, ExtraType.noball].contains(extra)
                      ? runs
                      : 0,
                  extraType: extra,
                  extraRuns: extra == ExtraType.none ? 0 : extras,
                  isWicket: widget.wicket,
                  wicketType: widget.wicket ? wicketType : '',
                  dismissedPlayerId: widget.wicket ? dismissed : '',
                  nextBatterId: nextBatter ?? '',
                );
                try {
                  const ScoringEngine().score(
                    widget.state,
                    delivery,
                    maxOvers: widget.maxOvers,
                    target: widget.target,
                  );
                  Navigator.pop(context, delivery);
                } on ArgumentError catch (e) {
                  setState(() => error = e.message.toString());
                } on StateError catch (e) {
                  setState(() => error = e.message);
                }
              },
              child: const Text('Save delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
