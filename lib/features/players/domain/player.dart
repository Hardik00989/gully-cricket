class Player {
  const Player(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get name => data['name'] as String? ?? '';
  String get role => data['role'] as String? ?? 'batter';
  String get roleLabel => switch (role) {
    'allrounder' => 'All-rounder',
    'keeper' => 'Wicketkeeper',
    'bowler' => 'Bowler',
    _ => 'Batter',
  };
  int get jerseyNo => (data['jerseyNo'] as num? ?? 0).toInt();
}
