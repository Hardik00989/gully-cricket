import 'package:flutter_test/flutter_test.dart';
import 'package:gully_crickett/features/scoring/domain/scoring_engine.dart';

void main() {
  const engine = ScoringEngine();
  InningsState initial({
    int runs = 0,
    int balls = 0,
    int wickets = 0,
    bool freeHit = false,
    List<String> dismissed = const [],
  }) => InningsState(
    battingTeamId: 'a',
    strikerId: 'a1',
    nonStrikerId: 'a2',
    bowlerId: 'b1',
    runs: runs,
    balls: balls,
    wickets: wickets,
    freeHit: freeHit,
    dismissed: dismissed,
  );
  test('odd runs rotate strike while boundaries keep it', () {
    final one = engine.score(
      initial(),
      const Delivery(runsOffBat: 1),
      maxOvers: 20,
    );
    expect(one.strikerId, 'a2');
    expect(one.runs, 1);
    expect(one.balls, 1);
    final four = engine.score(
      initial(),
      const Delivery(runsOffBat: 4),
      maxOvers: 20,
    );
    expect(four.strikerId, 'a1');
    expect(four.extras, 0);
  });
  test('sixth legal ball reverses strike and requires a new bowler', () {
    final dot = engine.score(initial(balls: 5), const Delivery(), maxOvers: 20);
    expect(dot.overs, '1.0');
    expect(dot.strikerId, 'a2');
    expect(dot.awaitingBowler, true);
    expect(
      () => engine.score(dot, const Delivery(), maxOvers: 20),
      throwsStateError,
    );
    final single = engine.score(
      initial(balls: 5),
      const Delivery(runsOffBat: 1),
      maxOvers: 20,
    );
    expect(single.strikerId, 'a1');
  });
  test('wide adds penalty and does not change legal balls or strike', () {
    final s = engine.score(
      initial(balls: 5),
      const Delivery(extraType: ExtraType.wide, extraRuns: 1),
      maxOvers: 20,
    );
    expect(s.runs, 1);
    expect(s.extras, 1);
    expect(s.balls, 5);
    expect(s.strikerId, 'a1');
    expect(s.awaitingBowler, false);
  });
  test('additional wide run rotates strike excluding penalty', () {
    final s = engine.score(
      initial(),
      const Delivery(extraType: ExtraType.wide, extraRuns: 2),
      maxOvers: 20,
    );
    expect(s.strikerId, 'a2');
    expect(s.runs, 2);
    expect(s.balls, 0);
  });
  test('no ball plus bat runs retains penalty and enables free hit', () {
    final s = engine.score(
      initial(),
      const Delivery(runsOffBat: 3, extraType: ExtraType.noball, extraRuns: 1),
      maxOvers: 20,
    );
    expect(s.runs, 4);
    expect(s.extras, 1);
    expect(s.balls, 0);
    expect(s.strikerId, 'a2');
    expect(s.freeHit, true);
  });
  test('byes and leg byes count as legal balls and extras', () {
    for (final type in [ExtraType.bye, ExtraType.legbye]) {
      final s = engine.score(
        initial(),
        Delivery(extraType: type, extraRuns: 3),
        maxOvers: 20,
      );
      expect(s.runs, 3);
      expect(s.extras, 3);
      expect(s.balls, 1);
      expect(s.strikerId, 'a2');
    }
  });
  test('wicket replaces dismissed striker and prevents reuse', () {
    final s = engine.score(
      initial(),
      const Delivery(
        isWicket: true,
        wicketType: 'bowled',
        dismissedPlayerId: 'a1',
        nextBatterId: 'a3',
      ),
      maxOvers: 20,
    );
    expect(s.wickets, 1);
    expect(s.strikerId, 'a3');
    expect(s.dismissed, ['a1']);
    expect(
      () => engine.score(
        initial(dismissed: ['a3']),
        const Delivery(
          isWicket: true,
          wicketType: 'caught',
          dismissedPlayerId: 'a1',
          nextBatterId: 'a3',
        ),
        maxOvers: 20,
      ),
      throwsArgumentError,
    );
  });
  test(
    'non-striker run out leaves other batter and rotates for completed run',
    () {
      final s = engine.score(
        initial(),
        const Delivery(
          runsOffBat: 1,
          isWicket: true,
          wicketType: 'run out',
          dismissedPlayerId: 'a2',
          nextBatterId: 'a3',
        ),
        maxOvers: 20,
      );
      expect(s.strikerId, 'a3');
      expect(s.nonStrikerId, 'a1');
      expect(s.wickets, 1);
    },
  );
  test('no ball and free hit reject a caught dismissal', () {
    expect(
      () => engine.score(
        initial(),
        const Delivery(
          extraType: ExtraType.noball,
          extraRuns: 1,
          isWicket: true,
          wicketType: 'caught',
          dismissedPlayerId: 'a1',
          nextBatterId: 'a3',
        ),
        maxOvers: 20,
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.score(
        initial(freeHit: true),
        const Delivery(
          isWicket: true,
          wicketType: 'caught',
          dismissedPlayerId: 'a1',
          nextBatterId: 'a3',
        ),
        maxOvers: 20,
      ),
      throwsArgumentError,
    );
  });
  test('free hit survives a wide and expires on the next legal delivery', () {
    final wide = engine.score(
      initial(freeHit: true),
      const Delivery(extraType: ExtraType.wide, extraRuns: 1),
      maxOvers: 20,
    );
    expect(wide.freeHit, true);
    final dot = engine.score(wide, const Delivery(), maxOvers: 20);
    expect(dot.freeHit, false);
  });
  test('tenth wicket closes innings without requiring next batter', () {
    final s = engine.score(
      initial(wickets: 9),
      const Delivery(
        isWicket: true,
        wicketType: 'bowled',
        dismissedPlayerId: 'a1',
      ),
      maxOvers: 20,
    );
    expect(s.closed, true);
    expect(s.wickets, 10);
  });
  test('overs limit closes innings', () {
    final s = engine.score(initial(balls: 5), const Delivery(), maxOvers: 1);
    expect(s.closed, true);
    expect(s.awaitingBowler, false);
    expect(
      () => engine.score(s, const Delivery(), maxOvers: 1),
      throwsStateError,
    );
  });
  test('chase can end on a wide before any legal ball', () {
    final s = engine.score(
      initial(runs: 10),
      const Delivery(extraType: ExtraType.wide, extraRuns: 1),
      maxOvers: 20,
      target: 11,
    );
    expect(s.closed, true);
    expect(s.balls, 0);
  });
  test(
    'negative runs, missing penalties and impossible extras are rejected',
    () {
      for (final ball in [
        const Delivery(runsOffBat: -1),
        const Delivery(extraType: ExtraType.wide),
        const Delivery(extraType: ExtraType.bye, runsOffBat: 1, extraRuns: 1),
        const Delivery(extraRuns: 1),
      ]) {
        expect(
          () => engine.score(initial(), ball, maxOvers: 20),
          throwsArgumentError,
        );
      }
    },
  );
  test('result covers runs, wickets and ties', () {
    MatchResult result(int runs) => engine.result(
      firstTeamId: 'a',
      firstTeamName: 'A',
      firstRuns: 100,
      secondTeamId: 'b',
      secondTeamName: 'B',
      secondRuns: runs,
      secondWickets: 3,
    );
    expect(result(101).summary, 'B won by 7 wickets');
    expect(result(101).winnerTeamId, 'b');
    expect(result(90).summary, 'A won by 10 runs');
    expect(result(100).summary, 'Match tied');
    expect(result(100).winnerTeamId, isNull);
  });
  test('NRR uses legal balls and handles zero denominators', () {
    expect(
      ScoringEngine.netRunRate(
        runsFor: 120,
        ballsFor: 90,
        runsAgainst: 100,
        ballsAgainst: 120,
      ),
      3,
    );
    expect(
      ScoringEngine.netRunRate(
        runsFor: 0,
        ballsFor: 0,
        runsAgainst: 0,
        ballsAgainst: 0,
      ),
      0,
    );
  });
  test('innings state round trip preserves scoring state for undo', () {
    final before = initial(
      runs: 37,
      balls: 17,
      wickets: 2,
      freeHit: true,
      dismissed: ['a4', 'a5'],
    );
    expect(InningsState.fromMap(before.toMap()).toMap(), before.toMap());
  });
}
