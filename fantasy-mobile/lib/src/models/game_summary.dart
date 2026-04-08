class GameSummary {
  const GameSummary({
    required this.id,
    this.startsAt,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.status,
    this.homeScore,
    this.awayScore,
  });

  final String id;
  final String? startsAt;
  final String homeTeamId;
  final String awayTeamId;
  final String status;
  final int? homeScore;
  final int? awayScore;

  factory GameSummary.fromMap(Map<String, dynamic> map) {
    return GameSummary(
      id: map['id'] as String? ?? '',
      startsAt: map['starts_at'] as String?,
      homeTeamId: map['home_team_id'] as String? ?? '',
      awayTeamId: map['away_team_id'] as String? ?? '',
      status: map['status'] as String? ?? 'scheduled',
      homeScore: map['home_score'] as int?,
      awayScore: map['away_score'] as int?,
    );
  }
}