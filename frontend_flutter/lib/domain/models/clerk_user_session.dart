/// Represents the active authenticated session managed by Clerk Auth.
class ClerkUserSession {
  final String userId;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String sessionToken;
  final String jwt;
  final DateTime expiresAt;
  final bool isGithubConnected;
  final String? githubUsername;

  const ClerkUserSession({
    required this.userId,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.sessionToken,
    required this.jwt,
    required this.expiresAt,
    this.isGithubConnected = false,
    this.githubUsername,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  ClerkUserSession copyWith({
    String? userId,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? sessionToken,
    String? jwt,
    DateTime? expiresAt,
    bool? isGithubConnected,
    String? githubUsername,
  }) {
    return ClerkUserSession(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      sessionToken: sessionToken ?? this.sessionToken,
      jwt: jwt ?? this.jwt,
      expiresAt: expiresAt ?? this.expiresAt,
      isGithubConnected: isGithubConnected ?? this.isGithubConnected,
      githubUsername: githubUsername ?? this.githubUsername,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'sessionToken': sessionToken,
        'jwt': jwt,
        'expiresAt': expiresAt.toIso8601String(),
        'isGithubConnected': isGithubConnected,
        'githubUsername': githubUsername,
      };

  factory ClerkUserSession.fromJson(Map<String, dynamic> json) => ClerkUserSession(
        userId: json['userId'] as String? ?? '',
        email: json['email'] as String? ?? '',
        fullName: json['fullName'] as String? ?? 'Developer',
        avatarUrl: json['avatarUrl'] as String?,
        sessionToken: json['sessionToken'] as String? ?? '',
        jwt: json['jwt'] as String? ?? '',
        expiresAt: json['expiresAt'] != null
            ? DateTime.tryParse(json['expiresAt'] as String) ??
                DateTime.now().add(const Duration(days: 7))
            : DateTime.now().add(const Duration(days: 7)),
        isGithubConnected: json['isGithubConnected'] as bool? ?? false,
        githubUsername: json['githubUsername'] as String?,
      );
}
