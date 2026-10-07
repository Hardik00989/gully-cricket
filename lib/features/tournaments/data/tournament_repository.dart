import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/tournament.dart';

class TournamentRepository {
  TournamentRepository(this.db);
  final FirebaseFirestore db;
  Stream<List<Tournament>> watchAll() => db
      .cricketCollection('tournaments')
      .snapshots()
      .map((s) => s.docs.map((d) => Tournament(d.id, d.data())).toList());
  Stream<Tournament?> watch(String id) => db
      .cricketCollection('tournaments')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Tournament(d.id, d.data()!) : null);
  Future<String> save(String? id, Map<String, dynamic> data) async {
    final doc = id == null
        ? db.cricketCollection('tournaments').doc()
        : db.cricketCollection('tournaments').doc(id);
    await doc.set(data, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> delete(String id) async {
    final matches = await db
        .cricketCollection('matches')
        .where('tournamentId', isEqualTo: id)
        .limit(1)
        .get();
    final teams = await db
        .cricketCollection('teams')
        .where('tournamentIds', arrayContains: id)
        .limit(1)
        .get();
    if (matches.docs.isNotEmpty || teams.docs.isNotEmpty) {
      throw StateError(
        'Remove this tournament’s matches and team memberships first.',
      );
    }
    await db.cricketCollection('tournaments').doc(id).delete();
  }
}
