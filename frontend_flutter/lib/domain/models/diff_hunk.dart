import 'package:uuid/uuid.dart';

/// Type of line within a unified diff.
enum DiffLineType {
  context,
  addition,
  deletion,
  hunkHeader,
  fileHeader,
}

/// Token representation for high-speed syntax highlighted rendering.
class SyntaxToken {
  final String text;
  final String? colorHex;
  final bool isKeyword;
  final bool isString;
  final bool isComment;
  final bool isType;

  const SyntaxToken({
    required this.text,
    this.colorHex,
    this.isKeyword = false,
    this.isString = false,
    this.isComment = false,
    this.isType = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'colorHex': colorHex,
        'isKeyword': isKeyword,
        'isString': isString,
        'isComment': isComment,
        'isType': isType,
      };

  factory SyntaxToken.fromJson(Map<String, dynamic> json) => SyntaxToken(
        text: json['text'] as String,
        colorHex: json['colorHex'] as String?,
        isKeyword: json['isKeyword'] as bool? ?? false,
        isString: json['isString'] as bool? ?? false,
        isComment: json['isComment'] as bool? ?? false,
        isType: json['isType'] as bool? ?? false,
      );
}

/// A single line in a diff hunk.
class DiffLine {
  final String id;
  final DiffLineType type;
  final String content;
  final int? oldLineNumber;
  final int? newLineNumber;
  final bool isSelected;
  final List<SyntaxToken> syntaxTokens;

  DiffLine({
    String? id,
    required this.type,
    required this.content,
    this.oldLineNumber,
    this.newLineNumber,
    this.isSelected = true,
    this.syntaxTokens = const [],
  }) : id = id ?? const Uuid().v4();

  DiffLine copyWith({
    String? id,
    DiffLineType? type,
    String? content,
    int? oldLineNumber,
    int? newLineNumber,
    bool? isSelected,
    List<SyntaxToken>? syntaxTokens,
  }) {
    return DiffLine(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      oldLineNumber: oldLineNumber ?? this.oldLineNumber,
      newLineNumber: newLineNumber ?? this.newLineNumber,
      isSelected: isSelected ?? this.isSelected,
      syntaxTokens: syntaxTokens ?? this.syntaxTokens,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'oldLineNumber': oldLineNumber,
        'newLineNumber': newLineNumber,
        'isSelected': isSelected,
        'syntaxTokens': syntaxTokens.map((t) => t.toJson()).toList(),
      };

  factory DiffLine.fromJson(Map<String, dynamic> json) => DiffLine(
        id: json['id'] as String?,
        type: DiffLineType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => DiffLineType.context,
        ),
        content: json['content'] as String,
        oldLineNumber: json['oldLineNumber'] as int?,
        newLineNumber: json['newLineNumber'] as int?,
        isSelected: json['isSelected'] as bool? ?? true,
        syntaxTokens: (json['syntaxTokens'] as List<dynamic>?)
                ?.map((t) => SyntaxToken.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// A hunk within a diff representing a contiguous chunk of changes.
class DiffHunk {
  final String id;
  final String filePath;
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final String header;
  final List<DiffLine> lines;
  final bool isSelected;

  DiffHunk({
    String? id,
    required this.filePath,
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.header,
    required this.lines,
    this.isSelected = true,
  }) : id = id ?? const Uuid().v4();

  int get additionsCount =>
      lines.where((l) => l.type == DiffLineType.addition).length;
  int get deletionsCount =>
      lines.where((l) => l.type == DiffLineType.deletion).length;

  DiffHunk copyWith({
    String? id,
    String? filePath,
    int? oldStart,
    int? oldLines,
    int? newStart,
    int? newLines,
    String? header,
    List<DiffLine>? lines,
    bool? isSelected,
  }) {
    return DiffHunk(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      oldStart: oldStart ?? this.oldStart,
      oldLines: oldLines ?? this.oldLines,
      newStart: newStart ?? this.newStart,
      newLines: newLines ?? this.newLines,
      header: header ?? this.header,
      lines: lines ?? this.lines,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'oldStart': oldStart,
        'oldLines': oldLines,
        'newStart': newStart,
        'newLines': newLines,
        'header': header,
        'lines': lines.map((l) => l.toJson()).toList(),
        'isSelected': isSelected,
      };

  factory DiffHunk.fromJson(Map<String, dynamic> json) => DiffHunk(
        id: json['id'] as String?,
        filePath: json['filePath'] as String,
        oldStart: json['oldStart'] as int? ?? 1,
        oldLines: json['oldLines'] as int? ?? 0,
        newStart: json['newStart'] as int? ?? 1,
        newLines: json['newLines'] as int? ?? 0,
        header: json['header'] as String? ?? '',
        lines: (json['lines'] as List<dynamic>?)
                ?.map((l) => DiffLine.fromJson(l as Map<String, dynamic>))
                .toList() ??
            const [],
        isSelected: json['isSelected'] as bool? ?? true,
      );
}

/// Diff summary for an individual file.
class FileDiff {
  final String filePath;
  final String? oldPath;
  final List<DiffHunk> hunks;
  final bool isNew;
  final bool isDeleted;
  final bool isRenamed;

  const FileDiff({
    required this.filePath,
    this.oldPath,
    required this.hunks,
    this.isNew = false,
    this.isDeleted = false,
    this.isRenamed = false,
  });

  int get additions =>
      hunks.fold(0, (sum, hunk) => sum + hunk.additionsCount);
  int get deletions =>
      hunks.fold(0, (sum, hunk) => sum + hunk.deletionsCount);

  FileDiff copyWith({
    String? filePath,
    String? oldPath,
    List<DiffHunk>? hunks,
    bool? isNew,
    bool? isDeleted,
    bool? isRenamed,
  }) {
    return FileDiff(
      filePath: filePath ?? this.filePath,
      oldPath: oldPath ?? this.oldPath,
      hunks: hunks ?? this.hunks,
      isNew: isNew ?? this.isNew,
      isDeleted: isDeleted ?? this.isDeleted,
      isRenamed: isRenamed ?? this.isRenamed,
    );
  }
}
