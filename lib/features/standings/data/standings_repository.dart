import '../../matches/domain/cricket_match.dart';
import '../../teams/domain/team.dart';
import '../domain/standing.dart';

class StandingsRepository {
  List<Standing> calculate(
    List<Team> teams,
    List<CricketMatch> matches,
    String tournamentId, {
    List<String> teamIds = const [],
  }) {
    final rows = {
      for (final t in teams.where(
        (t) => t.tournamentIds.contains(tournamentId) || teamIds.contains(t.id),
      ))
        t.id: Standing(teamId: t.id, name: t.shortName),
    };
    for (final m in matches.where(
      (m) =>
          m.tournamentId == tournamentId &&
          ['completed', 'abandoned'].contains(m.status),
    )) {
      final a = rows[m.teamAId], b = rows[m.teamBId];
      if (a == null || b == null) continue;
      a.played++;
      b.played++;
      if (m.status == 'abandoned') {
        a.noResult++;
        b.noResult++;
        a.points++;
        b.points++;
        continue;
      }
      final winner = m.result['winnerTeamId'];
      if (winner == null || winner == '') {
        a.tied++;
        b.tied++;
        a.points++;
        b.points++;
      } else {
        final won = winner == a.teamId ? a : b,
            lost = winner == a.teamId ? b : a;
        won.won++;
        won.points += 2;
        lost.lost++;
      }
      for (final i in m.innings) {
        final batting = i['battingTeamId'] == a.teamId ? a : b;
        final bowling = batting == a ? b : a;
        final runs = (i['runs'] as num).toInt();
        final balls = (i['wickets'] as num).toInt() >= 10
            ? m.overs * 6
            : (i['balls'] as num).toInt();
        batting.runsFor += runs;
        batting.ballsFor += balls;
        bowling.runsAgainst += runs;
        bowling.ballsAgainst += balls;
      }
    }
    return rows.values.toList()..sort((a, b) {
      final points = b.points.compareTo(a.points);
      return points != 0 ? points : b.nrr.compareTo(a.nrr);
    });
  }
}
