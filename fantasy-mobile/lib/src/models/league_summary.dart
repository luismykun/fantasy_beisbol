class LeagueSummary {
  const LeagueSummary({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.draftState,
    this.fantasyTeamName,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String draftState;
  final String? fantasyTeamName;

  factory LeagueSummary.fromMap(
    Map<String, dynamic> map, {
    String? fantasyTeamName,
  }) {
    return LeagueSummary(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Liga',
      inviteCode: map['invite_code'] as String? ?? '',
      draftState: map['draft_state'] as String? ?? 'pending',
      fantasyTeamName: fantasyTeamName,
    );
  }
}