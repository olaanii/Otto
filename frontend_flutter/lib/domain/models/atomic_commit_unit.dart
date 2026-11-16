import 'package:uuid/uuid.dart';

enum CommitStatus {
  draft,
  inReview,
  readyToPush,
  pushed,
  merged,
  conflicted,
}

/// Represents an individual atomic commit within an Otto stacked PR chain.
class AtomicCommitUnit {
  final String id;
  final String summary;
  final String? description;
  final String type; // e.g. feat, fix, refactor, chore
  final String? scope;
  final String author;
  final DateTime timestamp;
  final List<String> changedFiles;
  final int additions;
  final int deletions;
  final int? prNumber;
  final String branchName;
  final String? parentCommitId;
  final bool isPushed;
  final CommitStatus status;
  final String? agentProfileId;

  AtomicCommitUnit({
    String? id,
    required this.summary,
    this.description,
    this.type = 'feat',
    this.scope,
    this.author = 'Otto User',
    DateTime? timestamp,
    this.changedFiles = const [],
    this.additions = 0,
    this.deletions = 0,
    this.prNumber,
    required this.branchName,
    this.parentCommitId,
    this.isPushed = false,
    this.status = CommitStatus.draft,
    this.agentProfileId,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  int get totalLoc => additions + deletions;

  bool get exceedsLocThreshold => totalLoc > 80;
  bool get exceedsFileThreshold => changedFiles.length > 3;

  String get conventionalTitle {
    final scopePart = (scope != null && scope!.isNotEmpty) ? '($scope)' : '';
    return '$type$scopePart: $summary';
  }

  AtomicCommitUnit copyWith({
    String? id,
    String? summary,
    String? description,
    String? type,
    String? scope,
    String? author,
    DateTime? timestamp,
    List<String>? changedFiles,
    int? additions,
    int? deletions,
    int? prNumber,
    String? branchName,
    String? parentCommitId,
    bool? isPushed,
    CommitStatus? status,
    String? agentProfileId,
  }) {
    return AtomicCommitUnit(
      id: id ?? this.id,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      changedFiles: changedFiles ?? this.changedFiles,
      additions: additions ?? this.additions,
      deletions: deletions ?? this.deletions,
      prNumber: prNumber ?? this.prNumber,
      branchName: branchName ?? this.branchName,
      parentCommitId: parentCommitId ?? this.parentCommitId,
      isPushed: isPushed ?? this.isPushed,
      status: status ?? this.status,
      agentProfileId: agentProfileId ?? this.agentProfileId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'summary': summary,
        'description': description,
        'type': type,
        'scope': scope,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
        'changedFiles': changedFiles,
        'additions': additions,
        'deletions': deletions,
        'prNumber': prNumber,
        'branchName': branchName,
        'parentCommitId': parentCommitId,
        'isPushed': isPushed,
        'status': status.name,
        'agentProfileId': agentProfileId,
      };

  factory AtomicCommitUnit.fromJson(Map<String, dynamic> json) => AtomicCommitUnit(
        id: json['id'] as String?,
        summary: json['summary'] as String? ?? 'Untitled Commit',
        description: json['description'] as String?,
        type: json['type'] as String? ?? 'feat',
        scope: json['scope'] as String?,
        author: json['author'] as String? ?? 'Otto User',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        changedFiles: (json['changedFiles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        additions: json['additions'] as int? ?? 0,
        deletions: json['deletions'] as int? ?? 0,
        prNumber: json['prNumber'] as int?,
        branchName: json['branchName'] as String? ?? 'stack-branch',
        parentCommitId: json['parentCommitId'] as String?,
        isPushed: json['isPushed'] as bool? ?? false,
        status: CommitStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => CommitStatus.draft,
        ),
        agentProfileId: json['agentProfileId'] as String?,
      );
}
