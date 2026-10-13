import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/cricket_match.dart';

class MatchRepository {
  MatchRepository(this.db);
  final FirebaseFirestore db;
  Stream<List<Map<String, dynamic>>> watchBalls(String id) => db
      .cricketCollection('matches')
      .doc(id)
      .collection('balls')
      .orderBy('sequence')
      .snapshots()
      .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  Stream<List<CricketMatch>> watchAll() => db
      .cricketCollection('matches')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => CricketMatch(d.id, d.data())).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
      );
  Stream<CricketMatch?> watch(String id) => db
      .cricketCollection('matches')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? CricketMatch(d.id, d.data()!) : null);
  Future<String> save(String? id, Map<String, dynamic> data) async {
    final doc = id == null
        ? db.cricketCollection('matches').doc()
        : db.cricketCollection('matches').doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(doc);
      final tournament = await tx.get(
        db.cricketCollection('tournaments').doc(data['tournamentId'] as String),
      );
      final teamA = await tx.get(
        db.cricketCollection('teams').doc(data['teamAId'] as String),
      );
      final teamB = await tx.get(
        db.cricketCollection('teams').doc(data['teamBId'] as String),
      );
      if (!tournament.exists ||
          !teamA.exists ||
          !teamB.exists ||
          teamA.id == teamB.id ||
          !List<String>.from(
                teamA.data()!['tournamentIds'] as List? ?? [],
              ).contains(tournament.id) &&
              !List<String>.from(
                tournament.data()!['teamIds'] as List? ?? [],
              ).contains(teamA.id) ||
          !List<String>.from(
                teamB.data()!['tournamentIds'] as List? ?? [],
              ).contains(tournament.id) &&
              !List<String>.from(
                tournament.data()!['teamIds'] as List? ?? [],
              ).contains(teamB.id)) {
        throw StateError(
          'Select a tournament and two teams that belong to it.',
        );
      }
      final overs = data['overs'] as int;
      if (overs < 1 || overs > 50) {
        throw ArgumentError('Overs must be between 1 and 50.');
      }
      if (existing.exists && existing.data()!['status'] != 'upcoming') {
        throw StateError('Only upcoming fixtures can be edited.');
      }
      tx.set(doc, {
        ...data,
        'teamAName': teamA.data()!['name'],
        'teamBName': teamB.data()!['name'],
        'teamAShort': teamA.data()!['shortName'],
        'teamBShort': teamB.data()!['shortName'],
        if (!existing.exists) ...{
          'status': 'upcoming',
          'innings': <Map<String, dynamic>>[],
          'currentInnings': 0,
          'revision': 0,
        },
      }, SetOptions(merge: true));
    });

    return doc.id;
  }

  Future<void> delete(String id) async {
    final doc = db.cricketCollection('matches').doc(id);
    await db.runTransaction((tx) async {
      final match = await tx.get(doc);
      if (!match.exists) {
        return;
      }
      if (match.data()!['status'] == 'live') {
        throw StateError('End or abandon a live match before deleting it.');
      }
      tx.delete(doc);
    });
    while (true) {
      final balls = await doc.collection('balls').limit(400).get();
      if (balls.docs.isEmpty) {
        break;
      }
      final batch = db.batch();
      for (final ball in balls.docs) {
        batch.delete(ball.reference);
      }
      await batch.commit();
    }
  }
}
