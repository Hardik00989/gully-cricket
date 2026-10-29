import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gully_crickett/core/theme/app_theme.dart';
import 'package:gully_crickett/features/matches/domain/cricket_match.dart';
import 'package:gully_crickett/features/matches/presentation/match_card.dart';
import 'package:gully_crickett/features/scoring/domain/scoring_engine.dart';
import 'package:gully_crickett/features/scoring/presentation/scoreboard_header.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  final match = CricketMatch('match', {
    'teamAId': 'a',
    'teamBId': 'b',
    'teamAName': 'Home XI',
    'teamBName': 'Away XI',
    'teamAShort': 'HMX',
    'teamBShort': 'AWX',
    'status': 'live',
    'overs': 20,
    'innings': [
      {'battingTeamId': 'a', 'runs': 142, 'wickets': 4, 'balls': 99},
    ],
    'strikerName': 'Home batter',
    'nonStrikerName': 'Other batter',
    'bowlerName': 'Away bowler',
  });
  for (final dark in [false, true]) {
    testWidgets('scoreboards fit a narrow screen with large text, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                MatchCard(match: match),
                ScoreboardHeader(
                  match: match,
                  state: const InningsState(
                    battingTeamId: 'a',
                    strikerId: 's',
                    nonStrikerId: 'n',
                    bowlerId: 'b',
                    runs: 142,
                    wickets: 4,
                    balls: 99,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
