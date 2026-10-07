import '../../../core/utils/firestore_values.dart';

class Tournament {
  const Tournament(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  List<String> get teamIds => List<String>.from(data['teamIds'] as List? ?? []);
  String get name => data['name'] as String? ?? '';
  String get location => data['location'] as String? ?? '';
  String get format => data['format'] as String? ?? '';
  String get status => data['status'] as String? ?? 'upcoming';
  DateTime get startDate => readDate(data['startDate']);
  DateTime get endDate => readDate(data['endDate']);
}
