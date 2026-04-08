import 'package:fantasy_mobile/src/models/game_summary.dart';
import 'package:fantasy_mobile/src/models/player_summary.dart';
import 'package:fantasy_mobile/src/models/team_summary.dart';

class HomeFeed {
  const HomeFeed({
    this.teams = const <TeamSummary>[],
    this.players = const <PlayerSummary>[],
    this.games = const <GameSummary>[],
  });

  final List<TeamSummary> teams;
  final List<PlayerSummary> players;
  final List<GameSummary> games;
}