import 'dart:isolate';
import '../../domain/models/diff_hunk.dart';
import 'syntax_highlighter_isolate.dart';

/// Request payload sent to the diff tokenizer isolate.
class DiffTokenizeRequest {
  final String rawUnifiedDiff;
  final bool shouldHighlightSyntax;

  const DiffTokenizeRequest({
    required this.rawUnifiedDiff,
    this.shouldHighlightSyntax = true,
  });
}

/// High-performance diff parser and tokenizer running in a dedicated background Isolate.
/// Ensures 120 FPS rendering on modern displays by keeping diff parsing off the main UI isolate.
class DiffTokenizerIsolate {
  const DiffTokenizerIsolate._();

  /// Parse raw unified diff string in an isolated thread.
  static Future<List<FileDiff>> parseDiffAsync(DiffTokenizeRequest request) async {
    return Isolate.run(() => parseDiffSync(request));
  }

  /// Synchronous parser implementation for background isolate execution.
  static List<FileDiff> parseDiffSync(DiffTokenizeRequest request) {
    final raw = request.rawUnifiedDiff;
    if (raw.trim().isEmpty) return const [];

    final rawLines = raw.split('\n');
    final fileDiffs = <FileDiff>[];

    String? currentOldPath;
    String? currentNewPath;
    var isNew = false;
    var isDeleted = false;
    var isRenamed = false;
    List<DiffHunk> currentHunks = [];

    DiffHunk? currentHunk;
    var currentHunkLines = <DiffLine>[];

    int oldLineTracker = 0;
    int newLineTracker = 0;

    void flushCurrentHunk() {
      if (currentHunk != null) {
        currentHunks.add(currentHunk!.copyWith(lines: List.from(currentHunkLines)));
        currentHunk = null;
        currentHunkLines = [];
      }
    }

    void flushCurrentFile() {
      flushCurrentHunk();
      if (currentNewPath != null || currentOldPath != null) {
        final filePath = currentNewPath ?? currentOldPath ?? 'unknown';
        fileDiffs.add(
          FileDiff(
            filePath: filePath,
            oldPath: currentOldPath,
            hunks: List.from(currentHunks),
            isNew: isNew,
            isDeleted: isDeleted,
            isRenamed: isRenamed,
          ),
        );
        currentOldPath = null;
        currentNewPath = null;
        currentHunks = [];
        isNew = false;
        isDeleted = false;
        isRenamed = false;
      }
    }

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];

      // Git diff file header
      if (line.startsWith('diff --git ')) {
        flushCurrentFile();
        final parts = line.split(' ');
        if (parts.length >= 4) {
          currentOldPath = parts[2].replaceFirst(RegExp(r'^[a-z]/'), '');
          currentNewPath = parts[3].replaceFirst(RegExp(r'^[a-z]/'), '');
        }
        continue;
      }

      if (line.startsWith('new file mode ')) {
        isNew = true;
        continue;
      }
      if (line.startsWith('deleted file mode ')) {
        isDeleted = true;
        continue;
      }
      if (line.startsWith('similarity index ') || line.startsWith('rename from ')) {
        isRenamed = true;
        continue;
      }

      if (line.startsWith('--- ')) {
        if (!isNew) {
          final p = line.substring(4).trim();
          currentOldPath = p.replaceFirst(RegExp(r'^[a-z]/'), '');
        }
        continue;
      }

      if (line.startsWith('+++ ')) {
        if (!isDeleted) {
          final p = line.substring(4).trim();
          currentNewPath = p.replaceFirst(RegExp(r'^[a-z]/'), '');
        }
        continue;
      }

      // Hunk header: @@ -oldStart,oldLines +newStart,newLines @@ optional header
      if (line.startsWith('@@ ')) {
        flushCurrentHunk();

        final match = RegExp(r'^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(.*)').firstMatch(line);
        if (match != null) {
          final oldStart = int.tryParse(match.group(1) ?? '1') ?? 1;
          final oldLines = int.tryParse(match.group(2) ?? '1') ?? 1;
          final newStart = int.tryParse(match.group(3) ?? '1') ?? 1;
          final newLines = int.tryParse(match.group(4) ?? '1') ?? 1;
          final headerText = match.group(5)?.trim() ?? '';

          oldLineTracker = oldStart;
          newLineTracker = newStart;

          final filePath = currentNewPath ?? currentOldPath ?? 'unknown';

          currentHunk = DiffHunk(
            filePath: filePath,
            oldStart: oldStart,
            oldLines: oldLines,
            newStart: newStart,
            newLines: newLines,
            header: headerText,
            lines: [],
          );
        }
        continue;
      }

      // Inside hunk content lines
      if (currentHunk != null) {
        final filePath = currentNewPath ?? currentOldPath ?? 'unknown';

        if (line.startsWith('+') && !line.startsWith('+++')) {
          final content = line.substring(1);
          final tokens = request.shouldHighlightSyntax
              ? SyntaxHighlighterIsolate.highlightLineSync(content, filePath)
              : const <SyntaxToken>[];

          currentHunkLines.add(
            DiffLine(
              type: DiffLineType.addition,
              content: content,
              newLineNumber: newLineTracker,
              syntaxTokens: tokens,
            ),
          );
          newLineTracker++;
        } else if (line.startsWith('-') && !line.startsWith('---')) {
          final content = line.substring(1);
          final tokens = request.shouldHighlightSyntax
              ? SyntaxHighlighterIsolate.highlightLineSync(content, filePath)
              : const <SyntaxToken>[];

          currentHunkLines.add(
            DiffLine(
              type: DiffLineType.deletion,
              content: content,
              oldLineNumber: oldLineTracker,
              syntaxTokens: tokens,
            ),
          );
          oldLineTracker++;
        } else if (line.startsWith(' ')) {
          final content = line.substring(1);
          final tokens = request.shouldHighlightSyntax
              ? SyntaxHighlighterIsolate.highlightLineSync(content, filePath)
              : const <SyntaxToken>[];

          currentHunkLines.add(
            DiffLine(
              type: DiffLineType.context,
              content: content,
              oldLineNumber: oldLineTracker,
              newLineNumber: newLineTracker,
              syntaxTokens: tokens,
            ),
          );
          oldLineTracker++;
          newLineTracker++;
        } else if (line.startsWith(r'\ No newline at end of file')) {
          // ignore or record trailing newline marker
        }
      }
    }

    flushCurrentFile();
    return fileDiffs;
  }
}
