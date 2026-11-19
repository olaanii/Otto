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
  final DateTime? lastActiveAt;

  const IdeAgentProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
    required this.iconKey,
    this.activeFiles = const [],
    this.currentPrompt,
    this.isActive = false,
    this.lastActiveAt,
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
        'lastActiveAt': lastActiveAt?.toIso8601String(),
      };

  factory IdeAgentProfile.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String? ?? 'agent').toLowerCase();
    final name = json['name'] as String? ?? id;
    final isConn = json['connected'] == true || json['isActive'] == true || json['status'] == 'watching_realtime';
    String desc = json['description'] as String? ?? '';
    String color = json['colorHex'] as String? ?? '#4285F4';
    if (id.contains('antigravity')) {
      desc = desc.isNotEmpty ? desc : 'Agent-first IDE & autonomous commit daemon';
      color = '#4285F4';
    } else if (id.contains('cursor')) {
      desc = desc.isNotEmpty ? desc : 'AI-first code editor & Composer';
      color = '#00D8A5';
    } else if (id.contains('vscode') || id.contains('code')) {
      desc = desc.isNotEmpty ? desc : 'Visual Studio Code & Copilot';
      color = '#007ACC';
    }
    return IdeAgentProfile(
      id: id,
      name: name,
      description: desc,
      colorHex: color,
      iconKey: json['iconKey'] as String? ?? id,
      activeFiles: (json['activeFiles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      currentPrompt: json['currentPrompt'] as String?,
      isActive: isConn,
      lastActiveAt: json['lastActiveAt'] != null ? DateTime.tryParse(json['lastActiveAt'] as String) : null,
    );
  }

  static List<IdeAgentProfile> get defaults => const [
        IdeAgentProfile(
          id: 'antigravity',
          name: 'Google Antigravity',
          description: 'Agent-first IDE & autonomous commit daemon',
          colorHex: '#4285F4',
          iconKey: 'antigravity',
        ),
        IdeAgentProfile(
          id: 'cursor',
          name: 'Cursor',
          description: 'AI code editor & Composer',
          colorHex: '#00D8A5',
          iconKey: 'cursor',
        ),
        IdeAgentProfile(
          id: 'vscode',
          name: 'VS Code',
          description: 'Visual Studio Code & Copilot',
          colorHex: '#007ACC',
          iconKey: 'vscode',
        ),
      ];
}
