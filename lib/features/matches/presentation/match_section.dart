import 'package:flutter/material.dart';
import '../../../core/theme/app_text.dart';
import '../domain/cricket_match.dart';
import 'match_card.dart';

class MatchSection extends StatelessWidget {
  const MatchSection({
    super.key,
    required this.title,
    required this.matches,
    this.horizontal = false,
  });
  final String title;
  final List<CricketMatch> matches;
  final bool horizontal;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(title, style: AppText.label),
      ),
      if (matches.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('No matches here yet.'),
        )
      else if (horizontal)
        SizedBox(
          height: (210 * MediaQuery.textScalerOf(context).scale(1)).clamp(
            210,
            400,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: constraints.maxWidth.clamp(0, 380),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: MatchCard(match: matches[i]),
                ),
              ),
            ),
          ),
        )
      else
        ...matches.take(5).map((m) => MatchCard(match: m)),
    ],
  );
}
