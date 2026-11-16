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
        'title': summary, // Server schema compatibility
        'description': description,
        'type': type,
        'scope': scope,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
        'changedFiles': changedFiles,
        'additions': additions,
        'totalAdditions': additions, // Server schema compatibility
        'deletions': deletions,
        'totalDeletions': deletions, // Server schema compatibility
        'prNumber': prNumber,
        'branchName': branchName,
        'parentCommitId': parentCommitId,
        'parentBranch': parentCommitId, // Server schema compatibility
        'isPushed': isPushed,
        'status': status.name,
        'agentProfileId': agentProfileId,
      };

  static CommitStatus parseStatus(dynamic rawStatus) {
    if (rawStatus == null) return CommitStatus.draft;
    final statusStr = rawStatus.toString().toLowerCase().trim();
    switch (statusStr) {
      case 'pr_open':
      case 'open':
      case 'inreview':
      case 'in_review':
        return CommitStatus.inReview;
      case 'staged':
      case 'queued':
      case 'readytopush':
      case 'ready_to_push':
        return CommitStatus.readyToPush;
      case 'pushed':
        return CommitStatus.pushed;
      case 'merged':
        return CommitStatus.merged;
      case 'conflicted':
        return CommitStatus.conflicted;
      case 'draft':
        return CommitStatus.draft;
      default:
        for (final val in CommitStatus.values) {
          if (val.name.toLowerCase() == statusStr) {
            return val;
          }
        }
        return CommitStatus.draft;
    }
  }

  factory AtomicCommitUnit.fromJson(Map<String, dynamic> json) {
    final status = parseStatus(json['status']);

    // Resilient parsing: accept 'title' or 'summary'
    final summary = (json['summary'] ?? json['title']) as String? ?? 'Untitled Commit';

    // Resilient parsing: accept 'totalAdditions' or 'additions'
    final rawAdditions = json['additions'] ?? json['totalAdditions'];
    final additions = (rawAdditions is num) ? rawAdditions.toInt() : 0;

    // Resilient parsing: accept 'totalDeletions' or 'deletions'
    final rawDeletions = json['deletions'] ?? json['totalDeletions'];
    final deletions = (rawDeletions is num) ? rawDeletions.toInt() : 0;

    // Resilient parsing: accept 'parentBranch' or 'parentCommitId'
    final parentCommitId = (json['parentCommitId'] ?? json['parentBranch']) as String?;

    // Extract changed files directly or dynamically from hunks
    List<String> files = const [];
    if (json['changedFiles'] is List) {
      files = (json['changedFiles'] as List).map((e) => e.toString()).toList();
    } else if (json['hunks'] is List) {
      files = (json['hunks'] as List)
          .map((h) => h is Map ? (h['filePath']?.toString()) : null)
          .whereType<String>()
          .toSet()
          .toList();
    }

    final isPushed = (json['isPushed'] as bool?) ??
        (status == CommitStatus.pushed ||
            status == CommitStatus.inReview ||
            status == CommitStatus.merged);

    final rawPr = json['prNumber'];
    final prNumber = (rawPr is num) ? rawPr.toInt() : null;

    final rawDate = json['timestamp'] ?? json['createdAt'];
    final timestamp = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    final description = (json['description'] as String?) ??
        (json['bodyBullets'] is List
            ? (json['bodyBullets'] as List).map((e) => e.toString()).join('\n')
            : null);

    return AtomicCommitUnit(
      id: (json['id'] ?? json['sha']) as String?,
      summary: summary,
      description: description,
      type: json['type'] as String? ?? 'feat',
      scope: json['scope'] as String?,
      author: json['author'] as String? ?? 'Otto User',
      timestamp: timestamp,
      changedFiles: files,
      additions: additions,
      deletions: deletions,
      prNumber: prNumber,
      branchName: json['branchName'] as String? ?? 'stack-branch',
      parentCommitId: parentCommitId,
      isPushed: isPushed,
      status: status,
      agentProfileId: json['agentProfileId'] as String?,
    );
  }
}
