import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/team.dart';

class TeamRepository {
  TeamRepository(this.db);
  final FirebaseFirestore db;
  Stream<List<Team>> watchAll() => db
      .cricketCollection('teams')
      .snapshots()
      .map((s) => s.docs.map((d) => Team(d.id, d.data())).toList());
  Stream<Team?> watch(String id) => db
      .cricketCollection('teams')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Team(d.id, d.data()!) : null);
  Future<String> save(String? id, Map<String, dynamic> data) async {
    final doc = id == null
        ? db.cricketCollection('teams').doc()
        : db.cricketCollection('teams').doc(id);
    final previous = await doc.get();
    final removed = List<String>.from(
      previous.data()?['tournamentIds'] as List? ?? [],
    ).where((t) => !(data['tournamentIds'] as List).contains(t)).toSet();
    if (removed.isNotEmpty) {
      final a = await db
          .cricketCollection('matches')
          .where('teamAId', isEqualTo: doc.id)
          .get();
      final b = await db
          .cricketCollection('matches')
          .where('teamBId', isEqualTo: doc.id)
          .get();
      if ([
        ...a.docs,
        ...b.docs,
      ].any((m) => removed.contains(m.data()['tournamentId']))) {
        throw StateError(
          'Keep tournament memberships that have existing matches.',
        );
      }
    }
    await doc.set(data, SetOptions(merge: true));
    return doc.id;
  }

  Future<void> delete(String id) async {
    final a = await db
        .cricketCollection('matches')
        .where('teamAId', isEqualTo: id)
        .limit(1)
        .get();
    final b = await db
        .cricketCollection('matches')
        .where('teamBId', isEqualTo: id)
        .limit(1)
        .get();
    if (a.docs.isNotEmpty || b.docs.isNotEmpty) {
      throw StateError('Delete this team’s matches first.');
    }
    final players = await db
        .cricketCollection('teams')
        .doc(id)
        .collection('players')
        .get();
    if (players.docs.isNotEmpty) {
      throw StateError('Remove this team’s players first.');
    }
    await db.cricketCollection('teams').doc(id).delete();
  }
}
