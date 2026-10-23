enum ExtraType { none, wide, noball, bye, legbye }

class Delivery {
  const Delivery({
    this.runsOffBat = 0,
    this.extraType = ExtraType.none,
    this.extraRuns = 0,
    this.isWicket = false,
    this.wicketType = '',
    this.dismissedPlayerId = '',
    this.nextBatterId = '',
  });
  final int runsOffBat, extraRuns;
  final ExtraType extraType;
  final bool isWicket;
  final String wicketType, dismissedPlayerId, nextBatterId;
  bool get legal =>
      extraType != ExtraType.wide && extraType != ExtraType.noball;
  int get total => runsOffBat + extraRuns;
  int get runningRuns => total - (legal ? 0 : 1);
  Map<String, dynamic> toMap() => {
    'runsOffBat': runsOffBat,
    'extraType': extraType.name,
    'extraRuns': extraRuns,
    'isWicket': isWicket,
    'wicketType': wicketType,
    'dismissedPlayerId': dismissedPlayerId,
  };
}

class InningsState {
  const InningsState({
    required this.battingTeamId,
    required this.strikerId,
    required this.nonStrikerId,
    required this.bowlerId,
    this.runs = 0,
    this.wickets = 0,
    this.balls = 0,
    this.extras = 0,
    this.closed = false,
    this.awaitingBowler = false,
    this.freeHit = false,
    this.dismissed = const [],
  });
  final String battingTeamId, strikerId, nonStrikerId, bowlerId;
  final int runs, wickets, balls, extras;
  final bool closed, awaitingBowler, freeHit;
  final List<String> dismissed;
  String get overs => '${balls ~/ 6}.${balls % 6}';
  double get runRate => balls == 0 ? 0 : runs * 6 / balls;
  Map<String, dynamic> toMap() => {
    'battingTeamId': battingTeamId,
    'strikerId': strikerId,
    'nonStrikerId': nonStrikerId,
    'bowlerId': bowlerId,
    'runs': runs,
    'wickets': wickets,
    'balls': balls,
    'extras': extras,
    'closed': closed,
    'awaitingBowler': awaitingBowler,
    'freeHit': freeHit,
    'dismissed': dismissed,
  };
  factory InningsState.fromMap(Map<String, dynamic> m) => InningsState(
    battingTeamId: m['battingTeamId'] as String,
    strikerId: m['strikerId'] as String? ?? '',
    nonStrikerId: m['nonStrikerId'] as String? ?? '',
    bowlerId: m['bowlerId'] as String? ?? '',
    runs: (m['runs'] as num? ?? 0).toInt(),
    wickets: (m['wickets'] as num? ?? 0).toInt(),
    balls: (m['balls'] as num? ?? 0).toInt(),
    extras: (m['extras'] as num? ?? 0).toInt(),
    closed: m['closed'] == true,
    awaitingBowler: m['awaitingBowler'] == true,
    freeHit: m['freeHit'] == true,
    dismissed: List<String>.from(m['dismissed'] as List? ?? []),
  );
}

class MatchResult {
  const MatchResult(this.winnerTeamId, this.summary);
  final String? winnerTeamId;
  final String summary;
  Map<String, dynamic> toMap() => {
    'winnerTeamId': winnerTeamId,
    'summary': summary,
  };
}

class ScoringEngine {
  const ScoringEngine();
  InningsState score(
    InningsState state,
    Delivery ball, {
    required int maxOvers,
    int? target,
  }) {
    if (maxOvers < 1 || state.closed || state.awaitingBowler) {
      throw StateError('Innings is closed or needs a new bowler.');
    }
    if ([
          state.strikerId,
          state.nonStrikerId,
          state.bowlerId,
        ].any((id) => id.isEmpty) ||
        state.strikerId == state.nonStrikerId) {
      throw StateError('Select two batters and a bowler.');
    }
    if (ball.runsOffBat < 0 || ball.runsOffBat > 6 || ball.extraRuns < 0) {
      throw ArgumentError('Invalid runs');
    }
    if ([ExtraType.wide, ExtraType.noball].contains(ball.extraType) &&
        ball.extraRuns < 1) {
      throw ArgumentError('A wide or no ball includes a penalty run.');
    }
    if (ball.extraType == ExtraType.none && ball.extraRuns != 0) {
      throw ArgumentError('Select an extra type.');
    }
    if ([
          ExtraType.wide,
          ExtraType.bye,
          ExtraType.legbye,
        ].contains(ball.extraType) &&
        ball.runsOffBat != 0) {
      throw ArgumentError('These extras cannot include runs off the bat.');
    }
    if ([ExtraType.bye, ExtraType.legbye].contains(ball.extraType) &&
        ball.extraRuns == 0) {
      throw ArgumentError('Enter extra runs.');
    }
    var striker = state.strikerId, nonStriker = state.nonStrikerId;
    final runs = state.runs + ball.total;
    final wickets = state.wickets + (ball.isWicket ? 1 : 0);
    final balls = state.balls + (ball.legal ? 1 : 0);
    final closed =
        wickets >= 10 ||
        balls >= maxOvers * 6 ||
        target != null && runs >= target;
    final dismissed = [...state.dismissed];
    if (ball.isWicket) {
      const kinds = [
        'bowled',
        'caught',
        'lbw',
        'stumped',
        'run out',
        'hit wicket',
        'obstructing the field',
      ];
      if (!kinds.contains(ball.wicketType) ||
          ![striker, nonStriker].contains(ball.dismissedPlayerId)) {
        throw ArgumentError('Select a dismissal and a batter at the crease.');
      }
      if (ball.dismissedPlayerId == nonStriker &&
          !['run out', 'obstructing the field'].contains(ball.wicketType)) {
        throw ArgumentError(
          'Only a run out or obstruction can dismiss the non-striker.',
        );
      }
      if ((!ball.legal && ball.extraType == ExtraType.noball ||
              state.freeHit) &&
          !['run out', 'obstructing the field'].contains(ball.wicketType)) {
        throw ArgumentError(
          'This dismissal is not allowed on a no ball or free hit.',
        );
      }
      if (ball.extraType == ExtraType.wide &&
          ![
            'stumped',
            'run out',
            'hit wicket',
            'obstructing the field',
          ].contains(ball.wicketType)) {
        throw ArgumentError('Invalid dismissal on a wide.');
      }
      if (ball.runsOffBat > 0 &&
          [
            'bowled',
            'caught',
            'lbw',
            'stumped',
            'hit wicket',
          ].contains(ball.wicketType)) {
        throw ArgumentError('This dismissal cannot include runs off the bat.');
      }
      dismissed.add(ball.dismissedPlayerId);
      if (!closed &&
          (ball.nextBatterId.isEmpty ||
              dismissed.contains(ball.nextBatterId) ||
              [striker, nonStriker].contains(ball.nextBatterId))) {
        throw ArgumentError('Select an unused next batter.');
      }
      if (ball.dismissedPlayerId == striker) {
        striker = closed ? '' : ball.nextBatterId;
      } else {
        nonStriker = closed ? '' : ball.nextBatterId;
      }
    }
    if (ball.runningRuns.isOdd) {
      final swap = striker;
      striker = nonStriker;
      nonStriker = swap;
    }
    final endOver = ball.legal && balls % 6 == 0;
    if (endOver) {
      final swap = striker;
      striker = nonStriker;
      nonStriker = swap;
    }
    return InningsState(
      battingTeamId: state.battingTeamId,
      strikerId: striker,
      nonStrikerId: nonStriker,
      bowlerId: state.bowlerId,
      runs: runs,
      wickets: wickets,
      balls: balls,
      extras: state.extras + ball.extraRuns,
      closed: closed,
      awaitingBowler: endOver && !closed,
      freeHit:
          ball.extraType == ExtraType.noball || !ball.legal && state.freeHit,
      dismissed: dismissed,
    );
  }

  MatchResult result({
    required String firstTeamId,
    required String firstTeamName,
    required int firstRuns,
    required String secondTeamId,
    required String secondTeamName,
    required int secondRuns,
    required int secondWickets,
  }) {
    if (secondRuns > firstRuns) {
      return MatchResult(
        secondTeamId,
        '$secondTeamName won by ${10 - secondWickets} wickets',
      );
    }
    if (secondRuns == firstRuns) {
      return const MatchResult(null, 'Match tied');
    }
    return MatchResult(
      firstTeamId,
      '$firstTeamName won by ${firstRuns - secondRuns} runs',
    );
  }

  static double netRunRate({
    required int runsFor,
    required int ballsFor,
    required int runsAgainst,
    required int ballsAgainst,
  }) =>
      (ballsFor == 0 ? 0 : runsFor * 6 / ballsFor) -
      (ballsAgainst == 0 ? 0 : runsAgainst * 6 / ballsAgainst);
}
