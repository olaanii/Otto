import 'dart:isolate';
import '../../domain/models/diff_hunk.dart';

/// Background worker and isolate service for syntax highlighting.
/// Supports Dart, TypeScript, JavaScript, Go, Rust, and Python.
class SyntaxHighlighterIsolate {
  const SyntaxHighlighterIsolate._();

  static const Set<String> _dartKeywords = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
    'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with',
    'yield',
  };

  static const Set<String> _tsKeywords = {
    'break', 'case', 'catch', 'class', 'const', 'continue', 'debugger',
    'default', 'delete', 'do', 'else', 'enum', 'export', 'extends', 'false',
    'finally', 'for', 'function', 'if', 'import', 'in', 'instanceof', 'new',
    'null', 'return', 'super', 'switch', 'this', 'throw', 'true', 'try',
    'typeof', 'var', 'void', 'while', 'with', 'as', 'implements', 'interface',
    'let', 'package', 'private', 'protected', 'public', 'static', 'yield',
    'any', 'boolean', 'constructor', 'declare', 'get', 'is', 'module',
    'require', 'number', 'readonly', 'set', 'string', 'symbol', 'type',
    'from', 'of',
  };

  static const Set<String> _goKeywords = {
    'break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else',
    'fallthrough', 'for', 'func', 'go', 'goto', 'if', 'import', 'interface',
    'map', 'package', 'range', 'return', 'select', 'struct', 'switch', 'type',
    'var', 'nil', 'true', 'false',
  };

  static const Set<String> _rustKeywords = {
    'as', 'async', 'await', 'break', 'const', 'continue', 'crate', 'dyn',
    'else', 'enum', 'extern', 'false', 'fn', 'for', 'if', 'impl', 'in', 'let',
    'loop', 'match', 'mod', 'move', 'mut', 'pub', 'ref', 'return', 'Self',
    'self', 'static', 'struct', 'super', 'trait', 'true', 'type', 'unsafe',
    'use', 'where', 'while',
  };

  static const Set<String> _pyKeywords = {
    'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break',
    'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
    'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal',
    'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
  };

  /// Tokenizes a single code line in the background isolate.
  static Future<List<SyntaxToken>> highlightLineAsync({
    required String code,
    required String filePath,
  }) async {
    return Isolate.run(() => highlightLineSync(code, filePath));
  }

  /// Tokenizes a batch of code lines in the background isolate.
  static Future<List<List<SyntaxToken>>> highlightBatchAsync({
    required List<String> lines,
    required String filePath,
  }) async {
    return Isolate.run(() {
      final ext = _detectExtension(filePath);
      return lines.map((line) => _tokenizeLine(line, ext)).toList();
    });
  }

  /// Synchronous fallback when isolate spawning is unnecessary.
  static List<SyntaxToken> highlightLineSync(String code, String filePath) {
    final ext = _detectExtension(filePath);
    return _tokenizeLine(code, ext);
  }

  static String _detectExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.dart')) return 'dart';
    if (lower.endsWith('.ts') || lower.endsWith('.tsx')) return 'ts';
    if (lower.endsWith('.js') || lower.endsWith('.jsx')) return 'ts';
    if (lower.endsWith('.go')) return 'go';
    if (lower.endsWith('.rs')) return 'rust';
    if (lower.endsWith('.py')) return 'py';
    return 'generic';
  }

  static List<SyntaxToken> _tokenizeLine(String line, String lang) {
    if (line.isEmpty) return const [];

    final tokens = <SyntaxToken>[];
    final keywords = switch (lang) {
      'dart' => _dartKeywords,
      'ts' => _tsKeywords,
      'go' => _goKeywords,
      'rust' => _rustKeywords,
      'py' => _pyKeywords,
      _ => _dartKeywords,
    };

    // Quick regex scanner for comment, string, word, symbols
    final pattern = RegExp(
      r'(//.*$)|(#.*$)|(".*?"|' + "'.*?'" + r'|`.*?`)|([a-zA-Z_]\w*)|(\d+)|([^\s\w])|(\s+)',
    );

    final matches = pattern.allMatches(line);

    for (final match in matches) {
      final text = match.group(0)!;
      final commentMatch = match.group(1) ?? match.group(2);
      final stringMatch = match.group(3);
      final wordMatch = match.group(4);
      final numberMatch = match.group(5);

      if (commentMatch != null) {
        tokens.add(SyntaxToken(text: text, isComment: true, colorHex: '#71717A'));
      } else if (stringMatch != null) {
        tokens.add(SyntaxToken(text: text, isString: true, colorHex: '#10B981'));
      } else if (wordMatch != null) {
        if (keywords.contains(wordMatch)) {
          tokens.add(SyntaxToken(text: text, isKeyword: true, colorHex: '#6366F1'));
        } else if (wordMatch.isNotEmpty && wordMatch[0].toUpperCase() == wordMatch[0] && RegExp(r'^[A-Z]').hasMatch(wordMatch)) {
          tokens.add(SyntaxToken(text: text, isType: true, colorHex: '#F59E0B'));
        } else {
          tokens.add(SyntaxToken(text: text));
        }
      } else if (numberMatch != null) {
        tokens.add(SyntaxToken(text: text, colorHex: '#EC4899'));
      } else {
        tokens.add(SyntaxToken(text: text));
      }
    }

    return tokens;
  }
}
