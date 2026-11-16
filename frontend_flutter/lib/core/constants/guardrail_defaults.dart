/// Default atomic git guardrail constants for Otto PR splitting and stack validation.
class GuardrailDefaults {
  const GuardrailDefaults._();

  /// Maximum recommended Lines of Code (additions + deletions) per atomic commit.
  static const int maxLocPerCommit = 80;

  /// Maximum recommended changed files per atomic commit.
  static const int maxFilesPerCommit = 3;

  /// Enforce single responsibility by warning when multiple domains/concerns are mixed.
  static const bool enforceSingleResponsibility = true;

  /// Maximum character length for conventional commit summary.
  static const int maxCommitSummaryLength = 72;

  /// Supported conventional commit prefixes.
  static const List<String> conventionalCommitTypes = [
    'feat',
    'fix',
    'refactor',
    'perf',
    'docs',
    'test',
    'chore',
    'build',
    'ci',
    'revert',
  ];

  /// Semantic tags assigned to IDE AI Agents (Claude Code, Cursor, Cline, Roo, GitHub Copilot).
  static const List<String> supportedIdeAgents = [
    'claude-code',
    'cursor-composer',
    'cline',
    'roo-code',
    'github-copilot',
    'windsurf-cascade',
  ];
}
