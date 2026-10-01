import 'package:cloud_firestore/cloud_firestore.dart';

const firestoreRoot = String.fromEnvironment('FIRESTORE_ROOT');

extension CricketCollections on FirebaseFirestore {
  CollectionReference<Map<String, dynamic>> cricketCollection(String name) =>
      collection(firestoreRoot.isEmpty ? name : '$firestoreRoot/$name');
}
