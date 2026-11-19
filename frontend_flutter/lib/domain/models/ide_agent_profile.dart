/// Information about an AI agent active in the developer's workspace
/// (e.g., Claude Code, Cursor Composer, Cline, Roo Code, Copilot).
class IdeAgentProfile {
  final String id;
  final String name;
  final String description;
  final String colorHex;
  final String iconKey;
  final List<String> activeFiles;
  final String? currentPrompt;
  final bool isActive;
  final DateTime lastActiveAt;

  const IdeAgentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    this.activeFiles = const [],
    this.currentPrompt,
    this.isActive = false,
    required this.lastActiveAt,
  });

  IdeAgentProfile copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    String? iconKey,
    List<String>? activeFiles,
    String? currentPrompt,
    bool? isActive,
    DateTime? lastActiveAt,
  }) {
    return IdeAgentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      activeFiles: activeFiles ?? this.activeFiles,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      isActive: isActive ?? this.isActive,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'colorHex': colorHex,
        'iconKey': iconKey,
        'activeFiles': activeFiles,
        'currentPrompt': currentPrompt,
        'isActive': isActive,
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory IdeAgentProfile.fromJson(Map<String, dynamic> json) => IdeAgentProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#6366F1',
        iconKey: json['iconKey'] as String? ?? 'bot',
        activeFiles: (json['activeFiles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        currentPrompt: json['currentPrompt'] as String?,
        isActive: json['isActive'] as bool? ??
            (json['status'] == 'watching_realtime' || json['status'] == 'active'),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.tryParse(json['lastActiveAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  static List<IdeAgentProfile> get defaults => const [];
}
