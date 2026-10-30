import 'package:flutter_test/flutter_test.dart';
import 'package:gully_crickett/features/teams/domain/team.dart';
import 'package:gully_crickett/features/matches/domain/cricket_match.dart';
import 'package:gully_crickett/features/standings/data/standings_repository.dart';

void main() {
  final teams = [
    Team('a', {
      'shortName': 'A',
      'tournamentIds': ['cup'],
    }),
    Team('b', {
      'shortName': 'B',
      'tournamentIds': ['cup'],
    }),
  ];
  CricketMatch match({
    String status = 'completed',
    String? winner = 'a',
    int aRuns = 100,
    int bRuns = 80,
    int aWickets = 10,
    int bWickets = 4,
  }) => CricketMatch('m', {
    'tournamentId': 'cup',
    'teamAId': 'a',
    'teamBId': 'b',
    'overs': 20,
    'status': status,
    'result': {'winnerTeamId': winner},
    'innings': [
      {'battingTeamId': 'a', 'runs': aRuns, 'wickets': aWickets, 'balls': 60},
      {'battingTeamId': 'b', 'runs': bRuns, 'wickets': bWickets, 'balls': 120},
    ],
  });
  test(
    'win awards two points, loss zero, and all-out uses full overs for NRR',
    () {
      final rows = StandingsRepository().calculate(teams, [match()], 'cup');
      expect(rows.first.teamId, 'a');
      expect(rows.first.points, 2);
      expect(rows.first.won, 1);
      expect(rows.first.nrr, closeTo(1, 0.001));
      expect(rows.last.nrr, closeTo(-1, 0.001));
      expect(rows.last.lost, 1);
    },
  );
  test(
    'ties and abandoned matches split points, abandoned scores do not affect NRR',
    () {
      final rows = StandingsRepository().calculate(teams, [
        match(winner: null, aRuns: 80),
        match(status: 'abandoned'),
      ], 'cup');
      for (final r in rows) {
        expect(r.points, 2);
        expect(r.played, 2);
        expect(r.tied, 1);
        expect(r.noResult, 1);
        expect(r.nrr, 0);
      }
    },
  );
  test('upcoming and live matches do not affect points', () {
    final rows = StandingsRepository().calculate(teams, [
      match(status: 'upcoming'),
      match(status: 'live'),
    ], 'cup');
    expect(rows.every((r) => r.played == 0 && r.points == 0), true);
  });
  test(
    'teams selected by a tournament appear without changing team memberships',
    () {
      final selected = [
        const Team('a', {'shortName': 'A', 'tournamentIds': []}),
        const Team('b', {'shortName': 'B', 'tournamentIds': []}),
      ];
      final rows = StandingsRepository().calculate(
        selected,
        [match()],
        'cup',
        teamIds: ['a', 'b'],
      );
      expect(rows.length, 2);
      expect(rows.first.teamId, 'a');
      expect(rows.first.points, 2);
    },
  );
}
