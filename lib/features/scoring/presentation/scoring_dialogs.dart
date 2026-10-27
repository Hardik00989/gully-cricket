import 'package:flutter/material.dart';
import '../../players/domain/player.dart';

Future<bool> confirmScoringAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ??
    false;
Future<String?> pickNextBowler(
  BuildContext context,
  List<Player> players,
  String current,
) => showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('Next bowler'),
    children: [
      for (final p in players.where((p) => p.id != current))
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, p.id),
          child: Text(p.name),
        ),
      if (!players.any((p) => p.id != current))
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Add another bowler to this squad.'),
        ),
    ],
  ),
);
