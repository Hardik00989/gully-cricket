import '../../../core/utils/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/domain/app_user.dart';

class AdminRepository {
  AdminRepository(this.db);
  final FirebaseFirestore db;
  Stream<List<AppUser>> watchUsers() => db
      .cricketCollection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  Future<void> changeRole(String uid, String role, String actingUid) async {
    if (uid == actingUid) {
      throw StateError('Ask another admin to change your role.');
    }
    if (!['admin', 'user'].contains(role)) {
      throw ArgumentError('Invalid role');
    }
    await db.cricketCollection('users').doc(uid).update({'role': role});
  }
}
