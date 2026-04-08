class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String? shortName;
  final String? logoUrl;

  factory TeamSummary.fromMap(Map<String, dynamic> map) {
    return TeamSummary(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Equipo',
      shortName: map['short_name'] as String?,
      logoUrl: map['logo_url'] as String?,
    );
  }
}