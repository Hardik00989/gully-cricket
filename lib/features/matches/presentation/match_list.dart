import 'package:flutter/material.dart';
import '../domain/cricket_match.dart';
import 'match_card.dart';

class MatchList extends StatelessWidget {
  const MatchList({
    super.key,
    required this.matches,
    this.emptyText = 'No matches here yet.',
  });
  final List<CricketMatch> matches;
  final String emptyText;
  @override
  Widget build(BuildContext context) => matches.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(emptyText),
          ),
        )
      : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (_, index) => MatchCard(match: matches[index]),
        );
}
