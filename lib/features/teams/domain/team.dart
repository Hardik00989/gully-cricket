class Team {
  const Team(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get name => data['name'] as String? ?? '';
  String get shortName => data['shortName'] as String? ?? '';
  String get logoUrl => data['logoUrl'] as String? ?? '';
  List<String> get tournamentIds =>
      List<String>.from(data['tournamentIds'] as List? ?? []);
}
