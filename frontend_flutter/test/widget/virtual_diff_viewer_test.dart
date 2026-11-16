import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/domain/models/diff_hunk.dart';
import 'package:otto_frontend/presentation/widgets/diff/virtual_diff_viewer.dart';

void main() {
  group('VirtualDiffViewer Widget Tests', () {
    final sampleHunk = DiffHunk(
      id: 'hunk-1',
      filePath: 'lib/main.dart',
      oldStart: 1,
      oldLines: 2,
      newStart: 1,
      newLines: 3,
      header: 'void main()',
      lines: [
        DiffLine(
          id: 'line-1',
          type: DiffLineType.deletion,
          content: 'runApp(const OldApp());',
          oldLineNumber: 1,
        ),
        DiffLine(
          id: 'line-2',
          type: DiffLineType.addition,
          content: 'runApp(const ProviderScope(child: OttoApp()));',
          newLineNumber: 1,
        ),
        DiffLine(
          id: 'line-3',
          type: DiffLineType.context,
          content: '}',
          oldLineNumber: 2,
          newLineNumber: 2,
        ),
      ],
    );

    final sampleFileDiff = FileDiff(
      filePath: 'lib/main.dart',
      hunks: [sampleHunk],
    );

    testWidgets('renders file tab and diff lines in virtual list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VirtualDiffViewer(
                fileDiffs: [sampleFileDiff],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check file tab
      expect(find.text('main.dart'), findsOneWidget);

      // Check hunk header text
      expect(find.textContaining('void main()'), findsOneWidget);

      // Check diff line contents
      expect(find.text('runApp(const OldApp());'), findsOneWidget);
      expect(find.text('runApp(const ProviderScope(child: OttoApp()));'), findsOneWidget);

      // Check LOC counter
      expect(find.textContaining('LOC'), findsWidgets);
    });

    testWidgets('renders empty state when fileDiffs list is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VirtualDiffViewer(
                fileDiffs: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Working tree clean'), findsOneWidget);
      expect(find.text('No uncommitted changes detected in repository.'), findsOneWidget);
    });
  });
}
