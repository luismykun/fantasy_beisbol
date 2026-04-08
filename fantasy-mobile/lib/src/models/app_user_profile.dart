class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.displayName,
    this.email,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? username;
  final String? avatarUrl;

  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      id: map['id'] as String? ?? '',
      email: map['email'] as String?,
      username: map['username'] as String?,
      displayName: map['display_name'] as String? ?? 'Manager',
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}