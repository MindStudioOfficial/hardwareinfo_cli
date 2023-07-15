import 'package:dart_console/dart_console.dart';

class ColoredString {
  String _text;
  CustomConsoleColor? color;

  String get text => _text;
  set text(String text) => _text = text;

  ColoredString(
    this._text, {
    this.color,
  });

  List<ColoredString> split(Pattern pattern) {
    // Split the internal text
    var parts = _text.split(pattern);
    // Map each part to a new ColoredString with the same color as the original
    var coloredParts = parts.map((part) => ColoredString(part, color: color)).toList();
    return coloredParts;
  }

  ColoredString operator [](int i) => ColoredString(_text[i], color: color);

  int get displayWidth => _text.displayWidth;
  int get length => _text.length;
  bool get isNotEmpty => _text.isNotEmpty;
  bool get isEmpty => _text.isEmpty;

  @override
  String toString() {
    return _text;
  }

  ColoredString copyWith({
    String? text,
    CustomConsoleColor? color,
  }) {
    return ColoredString(
      text ?? _text,
      color: color ?? this.color,
    );
  }
}

class CustomConsoleColor {
  ConsoleColor? foreground;
  ConsoleColor? background;

  CustomConsoleColor(this.foreground, [this.background]);

  String? get codeForeground => foreground?.ansiSetForegroundColorSequence;
  String? get codeBackground => background?.ansiSetBackgroundColorSequence;

  CustomConsoleColor copyWith({ConsoleColor? foreground, ConsoleColor? background}) {
    return CustomConsoleColor(
      foreground ?? this.foreground,
      background ?? this.background,
    );
  }
}

extension MergeExtension on ConsoleColor {
  CustomConsoleColor operator &(ConsoleColor other) => CustomConsoleColor(this, other);

  CustomConsoleColor get asForeground => CustomConsoleColor(this);
}
