import '../../../core/utils/firestore_values.dart';

class CricketMatch {
  const CricketMatch(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get tournamentId => data['tournamentId'] as String? ?? '';
  String get teamAId => data['teamAId'] as String? ?? '';
  String get teamBId => data['teamBId'] as String? ?? '';
  String get teamAName => data['teamAName'] as String? ?? '';
  String get teamBName => data['teamBName'] as String? ?? '';
  String get teamAShort => data['teamAShort'] as String? ?? initials(teamAName);
  String get teamBShort => data['teamBShort'] as String? ?? initials(teamBName);
  String get venue => data['venue'] as String? ?? '';
  String get status => data['status'] as String? ?? 'upcoming';
  DateTime get scheduledAt => readDate(data['scheduledAt']);
  int get overs => (data['overs'] as num? ?? 20).toInt();
  int get currentInnings => (data['currentInnings'] as num? ?? 0).toInt();
  int get revision => (data['revision'] as num? ?? 0).toInt();
  List<Map<String, dynamic>> get innings => readMaps(data['innings']);
  Map<String, dynamic> get result =>
      Map<String, dynamic>.from(data['result'] as Map? ?? {});
  String teamName(String id) => id == teamAId ? teamAName : teamBName;
  String scoreFor(String teamId) {
    final values = innings.where((i) => i['battingTeamId'] == teamId);
    if (values.isEmpty) return 'Yet to bat';
    final i = values.first;
    final balls = (i['balls'] as num? ?? 0).toInt();
    return '${i['runs']}/${i['wickets']}  (${balls ~/ 6}.${balls % 6})';
  }

  static String initials(String name) => name
      .split(' ')
      .where((s) => s.isNotEmpty)
      .take(3)
      .map((s) => s[0])
      .join()
      .toUpperCase();
}
