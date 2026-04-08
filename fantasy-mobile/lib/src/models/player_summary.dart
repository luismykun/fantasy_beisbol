class PlayerSummary {
  const PlayerSummary({
    required this.id,
    required this.fullName,
    this.position,
    this.teamId,
    this.status,
  });

  final String id;
  final String fullName;
  final String? position;
  final String? teamId;
  final String? status;

  factory PlayerSummary.fromMap(Map<String, dynamic> map) {
    return PlayerSummary(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Jugador',
      position: map['position'] as String?,
      teamId: map['team_id'] as String?,
      status: map['status'] as String?,
    );
  }
}