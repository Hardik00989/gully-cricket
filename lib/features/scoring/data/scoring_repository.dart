import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../matches/domain/cricket_match.dart';
import '../domain/scoring_engine.dart';

class ScoringRepository {
  ScoringRepository(this.db);
  final FirebaseFirestore db;
  final engine = const ScoringEngine();
  DocumentReference<Map<String, dynamic>> _doc(String id) =>
      db.cricketCollection('matches').doc(id);
  Future<void> _mutate(
    String id,
    int revision,
    Future<void> Function(
      Transaction,
      DocumentReference<Map<String, dynamic>>,
      CricketMatch,
    )
    action,
  ) => db.runTransaction((tx) async {
    final doc = _doc(id), snapshot = await tx.get(_doc(id));
    if (!snapshot.exists) {
      throw StateError('Match no longer exists.');
    }
    final match = CricketMatch(id, snapshot.data()!);
    if (match.revision != revision) {
      throw StateError(
        'Another scorer updated this match. Review the latest score and try again.',
      );
    }
    await action(tx, doc, match);
  });
  Future<Map<String, String>> _names(
    Transaction tx,
    CricketMatch m,
    String battingTeam,
    String striker,
    String nonStriker,
    String bowler,
  ) async {
    final bowlingTeam = battingTeam == m.teamAId ? m.teamBId : m.teamAId;
    final names = <String, String>{};
    for (final entry in [
      ('strikerName', battingTeam, striker),
      ('nonStrikerName', battingTeam, nonStriker),
      ('bowlerName', bowlingTeam, bowler),
    ]) {
      if (entry.$3.isEmpty) {
        names[entry.$1] = '';
        continue;
      }
      final player = await tx.get(
        db
            .cricketCollection('teams')
            .doc(entry.$2)
            .collection('players')
            .doc(entry.$3),
      );
      if (!player.exists) {
        throw StateError('Selected player no longer belongs to this squad.');
      }
      names[entry.$1] = player.data()!['name'] as String;
    }
    return names;
  }

  Map<String, dynamic> _header(InningsState s, Map<String, String> names) => {
    ...names,
  };
  Map<String, dynamic> _result(
    CricketMatch m,
    List<Map<String, dynamic>> innings,
  ) {
    if (innings.length != 2 || innings[1]['closed'] != true) return {};
    final a = InningsState.fromMap(innings[0]),
        b = InningsState.fromMap(innings[1]);
    return {
      'status': 'completed',
      'result': engine
          .result(
            firstTeamId: a.battingTeamId,
            firstTeamName: m.teamName(a.battingTeamId),
            firstRuns: a.runs,
            secondTeamId: b.battingTeamId,
            secondTeamName: m.teamName(b.battingTeamId),
            secondRuns: b.runs,
            secondWickets: b.wickets,
          )
          .toMap(),
    };
  }

  Future<void> start(
    String id,
    int revision, {
    required String striker,
    required String nonStriker,
    required String bowler,
    required String tossWinner,
    required String decision,
  }) => _mutate(id, revision, (tx, doc, m) async {
    final second = m.innings.isNotEmpty;
    if (second &&
        (m.status != 'live' ||
            m.currentInnings != 0 ||
            m.innings.first['closed'] != true)) {
      throw StateError('Finish the first innings before starting the chase.');
    }
    if (!second && m.status != 'upcoming') {
      throw StateError('This match cannot be started.');
    }
    if (![m.teamAId, m.teamBId].contains(tossWinner) ||
        !['bat', 'bowl'].contains(decision)) {
      throw ArgumentError('Select the toss result.');
    }
    final batting = second
        ? (m.innings.first['battingTeamId'] == m.teamAId
              ? m.teamBId
              : m.teamAId)
        : decision == 'bat'
        ? tossWinner
        : (tossWinner == m.teamAId ? m.teamBId : m.teamAId);
    if (striker == nonStriker) {
      throw ArgumentError('Select two different batters.');
    }
    final names = await _names(tx, m, batting, striker, nonStriker, bowler);
    final state = InningsState(
      battingTeamId: batting,
      strikerId: striker,
      nonStrikerId: nonStriker,
      bowlerId: bowler,
    );
    tx.update(doc, {
      'innings': [
        ...m.innings,
        {...state.toMap(), ...names},
      ],
      'currentInnings': second ? 1 : 0,
      'status': 'live',
      'lastBallId': '',
      'revision': revision + 1,
      ..._header(state, names),
      if (!second) 'toss': {'winnerTeamId': tossWinner, 'decision': decision},
    });
  });
  Future<void> score(String id, int revision, Delivery delivery) =>
      _mutate(id, revision, (tx, doc, m) async {
        if (m.status != 'live' || m.innings.isEmpty) {
          throw StateError('Start a live innings first.');
        }
        final before = InningsState.fromMap(m.innings[m.currentInnings]);
        final next = engine.score(
          before,
          delivery,
          maxOvers: m.overs,
          target: m.currentInnings == 1
              ? (m.innings.first['runs'] as num).toInt() + 1
              : null,
        );
        final names = await _names(
          tx,
          m,
          next.battingTeamId,
          next.strikerId,
          next.nonStrikerId,
          next.bowlerId,
        );
        final innings = [...m.innings];
        innings[m.currentInnings] = {...next.toMap(), ...names};
        final ballDoc = doc.collection('balls').doc();
        final restore = <String, dynamic>{
          for (final key in [
            'innings',
            'currentInnings',
            'status',
            'result',
            'strikerName',
            'nonStrikerName',
            'bowlerName',
            'lastBallId',
          ])
            key:
                m.data[key] ??
                (key == 'result'
                    ? <String, dynamic>{}
                    : key == 'lastBallId'
                    ? ''
                    : null),
        };
        tx.set(ballDoc, {
          ...delivery.toMap(),
          'innings': m.currentInnings,
          'over': before.balls ~/ 6,
          'ballInOver': before.balls % 6 + 1,
          'batterId': before.strikerId,
          'bowlerId': before.bowlerId,
          'batterName': m.data['strikerName'],
          'bowlerName': m.data['bowlerName'],
          'dismissedPlayerName': delivery.dismissedPlayerId == before.strikerId
              ? m.data['strikerName']
              : m.data['nonStrikerName'],
          'sequence': revision + 1,
          'before': restore,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(doc, {
          'innings': innings,
          'revision': revision + 1,
          'lastBallId': ballDoc.id,
          ..._header(next, names),
          ..._result(m, innings),
        });
      });
  Future<void> changeBowler(String id, int revision, String bowler) =>
      _mutate(id, revision, (tx, doc, m) async {
        if (m.status != 'live' || m.innings.isEmpty) {
          throw StateError('No live innings.');
        }
        final state = InningsState.fromMap(m.innings[m.currentInnings]);
        if (!state.awaitingBowler || state.closed) {
          throw StateError('The over has not ended.');
        }
        if (state.bowlerId == bowler) {
          throw ArgumentError('A bowler cannot bowl consecutive overs.');
        }
        final names = await _names(
          tx,
          m,
          state.battingTeamId,
          state.strikerId,
          state.nonStrikerId,
          bowler,
        );
        final innings = [...m.innings];
        innings[m.currentInnings] = {
          ...state.toMap(),
          'bowlerId': bowler,
          'awaitingBowler': false,
          ...names,
        };
        tx.update(doc, {
          'innings': innings,
          'bowlerName': names['bowlerName'],
          'revision': revision + 1,
        });
      });
  Future<void> endInnings(String id, int revision) =>
      _mutate(id, revision, (tx, doc, m) async {
        if (m.status != 'live' || m.innings.isEmpty) {
          throw StateError('No live innings.');
        }
        final innings = [...m.innings];
        innings[m.currentInnings] = {
          ...innings[m.currentInnings],
          'closed': true,
          'awaitingBowler': false,
        };
        tx.update(doc, {
          'innings': innings,
          'revision': revision + 1,
          ..._result(m, innings),
        });
      });
  Future<void> abandon(String id, int revision) =>
      _mutate(id, revision, (tx, doc, m) async {
        if (m.status == 'completed' || m.status == 'abandoned') {
          throw StateError('Match already ended.');
        }
        tx.update(doc, {
          'status': 'abandoned',
          'result': {'winnerTeamId': null, 'summary': 'Match abandoned'},
          'revision': revision + 1,
          'lastBallId': '',
        });
      });
  Future<void> undo(String id, int revision) =>
      _mutate(id, revision, (tx, doc, m) async {
        final last = m.data['lastBallId'] as String? ?? '';
        if (last.isEmpty || m.status == 'abandoned') {
          throw StateError('No delivery to undo in this innings.');
        }
        final ballRef = doc.collection('balls').doc(last);
        final ball = await tx.get(ballRef);
        if (!ball.exists || ball.data()!['innings'] != m.currentInnings) {
          throw StateError('Cannot undo across innings.');
        }
        tx.update(doc, {
          ...Map<String, dynamic>.from(ball.data()!['before'] as Map),
          'revision': revision + 1,
        });
        tx.delete(ballRef);
      });
}
