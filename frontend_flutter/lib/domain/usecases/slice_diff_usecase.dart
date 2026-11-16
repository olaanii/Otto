import '../models/atomic_commit_unit.dart';
import '../models/diff_hunk.dart';
import '../models/guardrail_policy.dart';
import '../repositories/i_git_repository.dart';
import '../../core/errors/failure.dart';

class SliceDiffUseCase {
  final IGitRepository gitRepository;

  SliceDiffUseCase(this.gitRepository);

  Future<AtomicCommitUnit> call({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> selectedHunks,
    GuardrailPolicy policy = const GuardrailPolicy(),
  }) async {
    if (selectedHunks.isEmpty) {
      throw const GuardrailViolationFailure('No diff hunks selected for commit');
    }

    final totalLines = selectedHunks.fold(
      0,
      (sum, h) => sum + h.additionsCount + h.deletionsCount,
    );
    final touchedFiles = selectedHunks.map((h) => h.filePath).toSet().toList();

    final candidate = AtomicCommitUnit(
      summary: summary,
      description: description,
      type: type,
      scope: scope,
      branchName: 'stack-${DateTime.now().millisecondsSinceEpoch}',
      additions: selectedHunks.fold(0, (sum, h) => sum + h.additionsCount),
      deletions: selectedHunks.fold(0, (sum, h) => sum + h.deletionsCount),
      changedFiles: touchedFiles,
    );

    final violations = policy.validateCommit(candidate);
    if (violations.isNotEmpty && totalLines > policy.maxLocPerCommit * 1.5) {
      // Hard guardrail rejection if grossly over limits
      throw GuardrailViolationFailure(
        'Commit exceeds guardrail limits: ${violations.join("; ")}',
        violations: violations,
      );
    }

    return gitRepository.createAtomicCommit(
      summary: summary,
      description: description,
      type: type,
      scope: scope,
      hunks: selectedHunks,
    );
  }
}
