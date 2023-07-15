import 'dart:async';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:hardwareinfo_cli/console/colored_string.dart';

class ConsoleRenderer {
  final Console console;
  late List<List<ColoredString>> _consoleArray;

  late int _width;
  late int _height;

  int get width => _width;
  int get height => _height;

  Function(int width, int height)? _onResize;

  late Timer _resizeCallbackTimer;

  ConsoleRenderer(this.console) {
    _width = console.windowWidth;
    _height = console.windowHeight;
    _consoleArray = _createConsoleArray();

    _resizeCallbackTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      int newWidth = console.windowWidth;
      int newHeight = console.windowHeight;

      if (newWidth != _width || newHeight != _height) {
        _width = newWidth;
        _height = newHeight;
        _onResize?.call(_width, _height);
      }
    });
  }

  void setResizeCallback(Function(int width, int height) onResize) {
    _onResize = onResize;
  }

  List<List<ColoredString>> _createConsoleArray() {
    // Create a 2D array representing the console
    final List<List<ColoredString>> array = List.generate(
      _height,
      (_) => List.generate(_width, (_) => ColoredString(" ")),
    );

    return array;
  }

  (int maxLen, int lineCount) renderText(
    int x,
    int y,
    String string, {
    int? maxWidth,
    CustomConsoleColor? color,
    bool? keepColor,
  }) {
    return renderColoredText(
      x,
      y,
      ColoredString(string, color: color),
      maxWidth: maxWidth,
      keepColor: keepColor,
    );
  }

  /// returns the width of the longest line
  (int maxLen, int lineCount) renderColoredText(
    int x,
    int y,
    ColoredString string, {
    int? maxWidth,
    bool? keepColor = false,
  }) {
    string.text = string.text.trim().replaceAll("\\", "\\\\");

    List<ColoredString> lines = string.split(RegExp(r'\r?\n'));

    maxWidth = maxWidth ?? _width; // If maxWidth is not provided, use _width

    List<ColoredString> newLines = [];

    for (ColoredString line in lines) {
      if (line.displayWidth > maxWidth) {
        List<ColoredString> wrappedLines = wordWrap(line, maxWidth);
        newLines.addAll(wrappedLines);
      } else {
        newLines.add(line);
      }
    }
    int longestLineLength = 0;

    for (int j = 0; j < newLines.length && (y + j) < _height; j++) {
      ColoredString line = newLines[j];
      longestLineLength = max(longestLineLength, line.displayWidth);
      for (int i = 0; i < line.displayWidth && (x + i) < _width; i++) {
        late ColoredString newVal;
        if (keepColor == true) {
          // only override text and keep color
          newVal = _consoleArray[y + j][x + i].copyWith(text: line[i].text);
        } else {
          newVal = line[i];
        }
        _consoleArray[y + j][x + i] = newVal;
      }
    }
    return (longestLineLength, newLines.length);
  }

  // Helper function to wrap text based on the provided width
  List<ColoredString> wordWrap(ColoredString string, int width) {
    List<ColoredString> lines = [];

    while (string.length > width) {
      int spaceIndex = string.text.lastIndexOf(' ', width);
      if (spaceIndex == -1) {
        spaceIndex = width; // If no space found, split at width
      }
      lines.add(ColoredString(string.text.substring(0, spaceIndex), color: string.color));
      string.text = string.text.substring(spaceIndex).trim(); // trim to remove leading space
    }

    if (string.isNotEmpty) {
      lines.add(string);
    }

    return lines;
  }

  (int finalWidth, int finalHeight) renderRect(
    int startX,
    int startY,
    int w,
    int h, {
    CustomConsoleColor? borderColor,
    CustomConsoleColor? fillColor,
  }) {
    borderColor?.background ??= fillColor?.background;
    fillColor?.background ??= borderColor?.background;
    w = min(w, _width);
    h = min(h, _height);

    int endX = min(_width - 1, startX + w - 1);
    int endY = min(_height - 1, startY + h - 1);

    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        void write(String s) {
          _consoleArray[y][x] = _consoleArray[y][x].copyWith(text: s, color: borderColor);
        }

        if (x == startX) {
          // * left side
          if (y == startY) {
            write("╭");
          } else if (y == endY) {
            write("╰");
          } else {
            write("│");
          }
        } else if (x == endX) {
          // *  right side
          if (y == startY) {
            write("╮");
          } else if (y == endY) {
            write("╯");
          } else {
            write("│");
          }
        } else {
          // * middle
          if (y == startY) {
            write("─");
          } else if (y == endY) {
            write("─");
          } else {
            // go to right side to skip middle part
            if (fillColor != null) {
              _consoleArray[y][x] = _consoleArray[y][x].copyWith(color: fillColor);
            } else {
              x = endX - 1;
            }
          }
        }
      }
    }
    return (endX - startX, endY - startY);
  }

  (int width, int height) renderTextBox(
    String text,
    int x,
    int y, {
    int? maxWidth,
    String? title,
    bool expandRect = false,
    CustomConsoleColor? borderColor,
    CustomConsoleColor? fillColor,
    CustomConsoleColor? titleColor,
  }) =>
      renderColoredTextBox(
        ColoredString(text, color: fillColor),
        x,
        y,
        maxWidth: maxWidth,
        expandRect: expandRect,
        title: title != null ? ColoredString(title, color: titleColor) : null,
        borderColor: borderColor,
      );

  (int width, int height) renderColoredTextBox(
    ColoredString text,
    int x,
    int y, {
    int? maxWidth,
    ColoredString? title,
    bool expandRect = false,
    CustomConsoleColor? borderColor,
  }) {
    ConsoleColor? titleBackground = title?.color?.background;
    titleBackground ??= borderColor?.background;
    titleBackground ??= text.color?.background;

    ConsoleColor? titleForeground = title?.color?.foreground;
    titleForeground ??= borderColor?.foreground;
    titleForeground ??= text.color?.foreground;

    var (int tWidth, int lineCount) = renderColoredText(
      x + 2,
      y + 1,
      text,
      maxWidth: maxWidth,
    );
    var (int rWidth, int rHeight) = renderRect(
      x,
      y,
      expandRect ? _width : tWidth + 4,
      expandRect ? _height : lineCount + 2,
      borderColor: borderColor,
      fillColor: text.color,
    );
    if (title != null) {
      renderColoredText(
        x + 1,
        y,
        title.copyWith(
          color: CustomConsoleColor(titleForeground, titleBackground),
        ),
        maxWidth: (maxWidth ?? _width) + 2,
      );
    }
    return (rWidth, rHeight);
  }

  void clear() {
    _consoleArray = _createConsoleArray();
  }

  void show() {
    console.resetCursorPosition();
    var pageBuffer = StringBuffer();
    for (var (int i, List<ColoredString> row) in _consoleArray.indexed) {
      var lineBuffer = StringBuffer();
      for (ColoredString char in row) {
        lineBuffer
          ..write(char.color?.codeForeground ?? "")
          ..write(char.color?.codeBackground ?? "")
          ..write(char.text)
          ..write("\x1b[0m");
      }
      lineBuffer.write('\x1b[0m'); // Reset the color after each line
      if (i != _consoleArray.length - 1) {
        lineBuffer.write("\n");
      }
      pageBuffer.write(lineBuffer);
    }
    console.write(pageBuffer);
    console.resetCursorPosition();
  }

  void dispose() {
    _resizeCallbackTimer.cancel();
  }
}

int lineCount(String str) {
  return str.split(RegExp(r'\r?\n')).length + 1;
}
