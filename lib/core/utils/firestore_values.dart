import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readDate(dynamic value) => value is Timestamp
    ? value.toDate()
    : value is String
    ? DateTime.parse(value)
    : DateTime.fromMillisecondsSinceEpoch(0);
List<Map<String, dynamic>> readMaps(dynamic value) => (value as List? ?? [])
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();
