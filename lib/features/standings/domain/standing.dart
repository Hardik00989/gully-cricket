import '../../scoring/domain/scoring_engine.dart';

class Standing {
  Standing({required this.teamId, required this.name});
  final String teamId, name;
  int played = 0, won = 0, lost = 0, tied = 0, noResult = 0, points = 0;
  int runsFor = 0, ballsFor = 0, runsAgainst = 0, ballsAgainst = 0;
  double get nrr => ScoringEngine.netRunRate(
    runsFor: runsFor,
    ballsFor: ballsFor,
    runsAgainst: runsAgainst,
    ballsAgainst: ballsAgainst,
  );
}
