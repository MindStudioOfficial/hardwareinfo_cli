import 'package:dart_console/dart_console.dart';
import 'package:hardwareinfo_cli/console/colored_string.dart';

class LogEntry {
  String message;
  LogLevel level;
  DateTime timestamp;

  LogEntry(this.message, this.level, this.timestamp);

  (String message, CustomConsoleColor color) getConsoleMessage() {
    return (
      message,
      switch (level) {
        LogLevel.info => ConsoleColor.green.asForeground,
        LogLevel.warning => ConsoleColor.yellow.asForeground,
        LogLevel.error => ConsoleColor.red.asForeground,
      }
    );
  }
}

enum LogLevel {
  info,
  warning,
  error,
}

Logger logger = Logger();

class Logger {
  static final Logger _logger = Logger._internal();
  factory Logger() {
    return _logger;
  }
  Logger._internal();

  void log(String message, {LogLevel level = LogLevel.info}) {
    _logEntries.add(LogEntry(message, level, DateTime.now()));
  }

  final List<LogEntry> _logEntries = [];

  List<LogEntry> get logEntries => _logEntries;
}
