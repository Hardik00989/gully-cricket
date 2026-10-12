import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/player.dart';

class PlayerRepository {
  PlayerRepository(this.db);
  final FirebaseFirestore db;
  Stream<List<Player>> watchTeam(String teamId) => db
      .cricketCollection('teams')
      .doc(teamId)
      .collection('players')
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => Player(d.id, d.data())).toList()
              ..sort((a, b) => a.jerseyNo.compareTo(b.jerseyNo)),
      );
  Future<void> save(
    String teamId,
    String? id,
    Map<String, dynamic> data,
  ) async {
    final players = db
        .cricketCollection('teams')
        .doc(teamId)
        .collection('players');
    await (id == null ? players.doc() : players.doc(id)).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String teamId, String id) async {
    final a = await db
        .cricketCollection('matches')
        .where('teamAId', isEqualTo: teamId)
        .get();
    final b = await db
        .cricketCollection('matches')
        .where('teamBId', isEqualTo: teamId)
        .get();
    if ([...a.docs, ...b.docs].any((m) => m.data()['status'] == 'live')) {
      throw StateError('Players cannot be removed during a live match.');
    }
    await db
        .cricketCollection('teams')
        .doc(teamId)
        .collection('players')
        .doc(id)
        .delete();
  }
}
