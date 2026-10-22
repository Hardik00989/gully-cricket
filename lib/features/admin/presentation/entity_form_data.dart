import '../../matches/domain/cricket_match.dart';
import '../../teams/domain/team.dart';

Map<String, dynamic> entityFormData(
  String kind,
  Map<String, dynamic> values,
  List<Team> teams,
) {
  final data = <String, dynamic>{};
  switch (kind) {
    case 'tournaments':
      if ((values['endDate'] as DateTime).isBefore(
        values['startDate'] as DateTime,
      )) {
        throw ArgumentError('End date must be on or after the start date.');
      }
      for (final key in [
        'name',
        'location',
        'startDate',
        'endDate',
        'format',
        'status',
        'teamIds',
      ]) {
        data[key] = values[key];
      }
    case 'teams':
      for (final key in ['name', 'shortName', 'logoUrl', 'tournamentIds']) {
        data[key] = values[key];
      }
      if ((data['shortName'] as String).isEmpty) {
        data['shortName'] = CricketMatch.initials(data['name'] as String);
      }
    case 'players':
      for (final key in ['name', 'role', 'jerseyNo']) {
        data[key] = values[key];
      }
    case 'matches':
      if (values['teamAId'] == values['teamBId']) {
        throw ArgumentError('Select two different teams.');
      }
      for (final key in [
        'tournamentId',
        'teamAId',
        'teamBId',
        'venue',
        'scheduledAt',
        'overs',
      ]) {
        data[key] = values[key];
      }
      final a = teams.firstWhere((t) => t.id == values['teamAId']);
      final b = teams.firstWhere((t) => t.id == values['teamBId']);
      data.addAll({
        'teamAName': a.name,
        'teamBName': b.name,
        'teamAShort': a.shortName,
        'teamBShort': b.shortName,
      });
      data['toss'] = values['tossWinner'] == null
          ? <String, dynamic>{}
          : {
              'winnerTeamId': values['tossWinner'],
              'decision': values['tossDecision'],
            };
  }
  return data;
}
