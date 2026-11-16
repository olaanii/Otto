import '../models/atomic_commit_unit.dart';
import '../../core/constants/guardrail_defaults.dart';

/// Guardrail configuration governing PR slicing and commit granularity.
class GuardrailPolicy {
  final int maxLocPerCommit;
  final int maxFilesPerCommit;
  final bool enforceConventionalCommits;
  final bool enforceSingleDomain;
  final List<String> allowedCommitTypes;

  const GuardrailPolicy({
    this.maxLocPerCommit = GuardrailDefaults.maxLocPerCommit,
    this.maxFilesPerCommit = GuardrailDefaults.maxFilesPerCommit,
    this.enforceConventionalCommits = true,
    this.enforceSingleDomain = GuardrailDefaults.enforceSingleResponsibility,
    this.allowedCommitTypes = GuardrailDefaults.conventionalCommitTypes,
  });

  /// Evaluates an atomic commit unit against policy guardrails.
  List<String> validateCommit(AtomicCommitUnit commit) {
    final violations = <String>[];

    if (commit.totalLoc > maxLocPerCommit) {
      violations.add(
        'Commit exceeds LOC threshold (${commit.totalLoc} > $maxLocPerCommit LOC)',
      );
    }

    if (commit.changedFiles.length > maxFilesPerCommit) {
      violations.add(
        'Commit touches too many files (${commit.changedFiles.length} > $maxFilesPerCommit files)',
      );
    }

    if (enforceConventionalCommits && !allowedCommitTypes.contains(commit.type.toLowerCase())) {
      violations.add(
        'Invalid conventional commit type "${commit.type}". Must be one of: ${allowedCommitTypes.join(", ")}',
      );
    }

    if (commit.summary.trim().isEmpty) {
      violations.add('Commit summary must not be empty');
    }

    if (commit.summary.length > GuardrailDefaults.maxCommitSummaryLength) {
      violations.add(
        'Commit summary exceeds ${GuardrailDefaults.maxCommitSummaryLength} characters',
      );
    }

    return violations;
  }

  GuardrailPolicy copyWith({
    int? maxLocPerCommit,
    int? maxFilesPerCommit,
    bool? enforceConventionalCommits,
    bool? enforceSingleDomain,
    List<String>? allowedCommitTypes,
  }) {
    return GuardrailPolicy(
      maxLocPerCommit: maxLocPerCommit ?? this.maxLocPerCommit,
      maxFilesPerCommit: maxFilesPerCommit ?? this.maxFilesPerCommit,
      enforceConventionalCommits:
          enforceConventionalCommits ?? this.enforceConventionalCommits,
      enforceSingleDomain: enforceSingleDomain ?? this.enforceSingleDomain,
      allowedCommitTypes: allowedCommitTypes ?? this.allowedCommitTypes,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxLocPerCommit': maxLocPerCommit,
        'maxFilesPerCommit': maxFilesPerCommit,
        'enforceConventionalCommits': enforceConventionalCommits,
        'enforceSingleDomain': enforceSingleDomain,
        'allowedCommitTypes': allowedCommitTypes,
      };

  factory GuardrailPolicy.fromJson(Map<String, dynamic> json) => GuardrailPolicy(
        maxLocPerCommit:
            json['maxLocPerCommit'] as int? ?? GuardrailDefaults.maxLocPerCommit,
        maxFilesPerCommit: json['maxFilesPerCommit'] as int? ??
            GuardrailDefaults.maxFilesPerCommit,
        enforceConventionalCommits:
            json['enforceConventionalCommits'] as bool? ?? true,
        enforceSingleDomain:
            json['enforceSingleDomain'] as bool? ?? true,
        allowedCommitTypes: (json['allowedCommitTypes'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            GuardrailDefaults.conventionalCommitTypes,
      );
}
