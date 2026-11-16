import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/isolates/diff_tokenizer_isolate.dart';
import 'package:otto_frontend/domain/models/diff_hunk.dart';

void main() {
  group('DiffTokenizerIsolate Tests', () {
    const rawDiffSample = '''
diff --git a/lib/core/constants.dart b/lib/core/constants.dart
index 83a21bc..47f89d1 100644
--- a/lib/core/constants.dart
+++ b/lib/core/constants.dart
@@ -10,4 +10,6 @@ class Constants {
   static const int maxLoc = 80;
-  static const bool debug = false;
+  static const bool debug = true;
+  static const String appName = 'Otto';
 }
''';

    test('parseDiffSync parses unified diff into structured FileDiff', () {
      final fileDiffs = DiffTokenizerIsolate.parseDiffSync(
        const DiffTokenizeRequest(rawUnifiedDiff: rawDiffSample),
      );

      expect(fileDiffs.length, 1);
      final fileDiff = fileDiffs.first;
      expect(fileDiff.filePath, 'lib/core/constants.dart');
      expect(fileDiff.hunks.length, 1);

      final hunk = fileDiff.hunks.first;
      expect(hunk.oldStart, 10);
      expect(hunk.newStart, 10);
      expect(hunk.additionsCount, 2);
      expect(hunk.deletionsCount, 1);

      final additionLines = hunk.lines.where((l) => l.type == DiffLineType.addition).toList();
      expect(additionLines.length, 2);
      expect(additionLines.first.content.trim(), 'static const bool debug = true;');
      expect(additionLines.last.content.trim(), "static const String appName = 'Otto';");

      final deletionLines = hunk.lines.where((l) => l.type == DiffLineType.deletion).toList();
      expect(deletionLines.length, 1);
      expect(deletionLines.first.content.trim(), 'static const bool debug = false;');
    });

    test('parseDiffSync handles multiple files and new file creation', () {
      const multiDiff = '''
diff --git a/new_file.dart b/new_file.dart
new file mode 100644
--- /dev/null
+++ b/new_file.dart
@@ -0,0 +1,2 @@
+void main() {
+}
diff --git a/deleted_file.dart b/deleted_file.dart
deleted file mode 100644
--- a/deleted_file.dart
+++ /dev/null
@@ -1,1 +0,0 @@
-class Old {}
''';

      final fileDiffs = DiffTokenizerIsolate.parseDiffSync(
        const DiffTokenizeRequest(rawUnifiedDiff: multiDiff),
      );

      expect(fileDiffs.length, 2);
      expect(fileDiffs[0].isNew, isTrue);
      expect(fileDiffs[0].filePath, 'new_file.dart');
      expect(fileDiffs[1].isDeleted, isTrue);
      expect(fileDiffs[1].filePath, 'deleted_file.dart');
    });
  });
}
