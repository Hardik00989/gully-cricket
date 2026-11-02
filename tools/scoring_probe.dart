import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gully_crickett/features/matches/data/match_repository.dart';
import 'package:gully_crickett/features/scoring/data/scoring_repository.dart';
import 'package:gully_crickett/features/scoring/domain/scoring_engine.dart';
import 'package:gully_crickett/features/standings/data/standings_repository.dart';
import 'package:gully_crickett/features/teams/domain/team.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var message = 'PASS';
  try {
    if (!const bool.fromEnvironment('USE_EMULATORS')) {
      throw StateError('Run this probe with USE_EMULATORS=true.');
    }
    await runProbe();
  } catch (error) {
    message = 'FAIL: $error';
  }
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text('SCORING_PROBE $message'))),
    ),
  );
}

void check(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected $expected, received $actual');
  }
}

Future<void> expectArgumentError(Future<void> operation) async {
  try {
    await operation;
  } catch (error) {
    if (error.toString().contains('This dismissal is not allowed')) {
      return;
    }
    rethrow;
  }
  throw StateError('Expected invalid delivery to be rejected.');
}

Future<void> runProbe() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'demo-api-key',
      appId: '1:123456789:web:demo',
      messagingSenderId: '123456789',
      projectId: 'demo-gully-cricket',
    ),
  );
  final db = FirebaseFirestore.instance;
  db.useFirestoreEmulator('127.0.0.1', 8080);
  await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: 'admin@gully.local',
    password: 'Cricket123!',
  );
  final doc = db.collection('matches').doc('integration-match');
  for (final ball in (await doc.collection('balls').get()).docs) {
    await ball.reference.delete();
  }
  await doc.delete();
  final scoring = ScoringRepository(db), matches = MatchRepository(db);
  for (final team in ['integration-a', 'integration-b']) {
    await db.collection('teams').doc(team).set({
      'name': team,
      'shortName': team.endsWith('a') ? 'A' : 'B',
      'tournamentIds': ['integration-cup'],
    });
    for (final id in ['p1', 'p2', 'p3']) {
      await db.collection('teams').doc(team).collection('players').doc(id).set({
        'name': '$team/$id',
        'role': 'allrounder',
        'jerseyNo': 1,
      });
    }
  }
  await doc.set({
    'tournamentId': 'integration-cup',
    'teamAId': 'integration-a',
    'teamBId': 'integration-b',
    'teamAName': 'A',
    'teamBName': 'B',
    'overs': 1,
    'status': 'upcoming',
    'innings': [],
    'currentInnings': 0,
    'revision': 0,
  });
  Future<Map<String, dynamic>> read() async => (await doc.get()).data()!;
  await scoring.start(
    doc.id,
    0,
    striker: 'p1',
    nonStriker: 'p2',
    bowler: 'p1',
    tossWinner: 'integration-a',
    decision: 'bat',
  );
  var m = await read();
  check(m['strikerName'], 'integration-a/p1');
  check(m['bowlerName'], 'integration-b/p1');
  final liveUpdate = matches
      .watch(doc.id)
      .firstWhere((m) => m?.innings.first['runs'] == 4)
      .timeout(const Duration(seconds: 15));
  await scoring.score(doc.id, 1, const Delivery(runsOffBat: 4));
  check((await liveUpdate)!.innings.first['balls'], 1);
  Future<bool> competingWrite() async {
    try {
      await scoring.score(doc.id, 2, const Delivery(runsOffBat: 1));
      return true;
    } catch (error) {
      if (error.toString().contains('Another scorer updated')) {
        return false;
      }
      rethrow;
    }
  }

  final outcomes = await Future.wait([competingWrite(), competingWrite()]);
  check(outcomes.where((ok) => ok).length, 1);
  m = await read();
  check(m['revision'], 3);
  check(m['innings'][0]['runs'], 5);
  await scoring.undo(doc.id, 3);
  m = await read();
  check(m['innings'][0]['runs'], 4);
  check(m['strikerName'], 'integration-a/p1');
  check((await doc.collection('balls').get()).docs.length, 1);
  await scoring.score(
    doc.id,
    4,
    const Delivery(runsOffBat: 2, extraType: ExtraType.noball, extraRuns: 1),
  );
  await expectArgumentError(
    scoring.score(
      doc.id,
      5,
      const Delivery(
        isWicket: true,
        wicketType: 'caught',
        dismissedPlayerId: 'p1',
        nextBatterId: 'p3',
      ),
    ),
  );
  check((await read())['revision'], 5);
  await scoring.score(doc.id, 5, const Delivery());
  await scoring.score(
    doc.id,
    6,
    const Delivery(
      isWicket: true,
      wicketType: 'bowled',
      dismissedPlayerId: 'p1',
      nextBatterId: 'p3',
    ),
  );
  m = await read();
  check(m['strikerName'], 'integration-a/p3');
  check(m['innings'][0]['wickets'], 1);
  await scoring.undo(doc.id, 7);
  m = await read();
  check(m['innings'][0]['wickets'], 0);
  check(m['strikerName'], 'integration-a/p1');
  await scoring.endInnings(doc.id, 8);
  await scoring.start(
    doc.id,
    9,
    striker: 'p1',
    nonStriker: 'p2',
    bowler: 'p1',
    tossWinner: 'integration-a',
    decision: 'bat',
  );
  await scoring.score(doc.id, 10, const Delivery(runsOffBat: 6));
  await scoring.score(doc.id, 11, const Delivery(runsOffBat: 2));
  m = await read();
  check(m['status'], 'completed');
  check(m['result']['summary'], 'B won by 10 wickets');
  final finished = (await matches.watch(doc.id).first)!;
  final table = StandingsRepository().calculate(
    [
      Team('integration-a', {
        'shortName': 'A',
        'tournamentIds': ['integration-cup'],
      }),
      Team('integration-b', {
        'shortName': 'B',
        'tournamentIds': ['integration-cup'],
      }),
    ],
    [finished],
    'integration-cup',
  );
  check(table.first.teamId, 'integration-b');
  check(table.first.points, 2);
  await scoring.undo(doc.id, 12);
  m = await read();
  check(m['status'], 'live');
  check((m['result'] as Map).isEmpty, true);
  check(m['innings'][1]['runs'], 6);
  await scoring.score(doc.id, 13, const Delivery(runsOffBat: 2));
  check((await read())['status'], 'completed');
  await matches.delete(doc.id);
  check((await doc.collection('balls').get()).docs.isEmpty, true);
  for (final team in ['integration-a', 'integration-b']) {
    for (final player
        in (await db.collection('teams').doc(team).collection('players').get())
            .docs) {
      await player.reference.delete();
    }
    await db.collection('teams').doc(team).delete();
  }
  await FirebaseAuth.instance.signOut();
}
