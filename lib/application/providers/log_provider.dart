import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LogLevel { error, warning, info }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String title;
  final String? details;
  final String? stackTrace;
  final String source;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.title,
    this.details,
    this.stackTrace,
    this.source = 'Git',
  });

  String toFullReport() {
    final buffer = StringBuffer();
    buffer.writeln('[$source - ${level.name.toUpperCase()}] $timestamp');
    buffer.writeln('Title: $title');
    if (details != null && details!.isNotEmpty) {
      buffer.writeln('\nDetails:\n$details');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.writeln('\nStack Trace:\n$stackTrace');
    }
    return buffer.toString();
  }
}

class LogState {
  final List<LogEntry> entries;
  final bool isPanelOpen;
  final int selectedTabIndex; // 0 = Errors, 1 = Warnings, 2 = Output/Info

  const LogState({
    this.entries = const [],
    this.isPanelOpen = false,
    this.selectedTabIndex = 0,
  });

  int get errorCount => entries.where((e) => e.level == LogLevel.error).length;
  int get warningCount =>
      entries.where((e) => e.level == LogLevel.warning).length;

  List<LogEntry> get filteredEntries {
    if (selectedTabIndex == 0) {
      return entries.where((e) => e.level == LogLevel.error).toList();
    } else if (selectedTabIndex == 1) {
      return entries.where((e) => e.level == LogLevel.warning).toList();
    } else {
      return entries;
    }
  }

  LogState copyWith({
    List<LogEntry>? entries,
    bool? isPanelOpen,
    int? selectedTabIndex,
  }) {
    return LogState(
      entries: entries ?? this.entries,
      isPanelOpen: isPanelOpen ?? this.isPanelOpen,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class LogNotifier extends Notifier<LogState> {
  static const int maxEntries = 500;

  @override
  LogState build() => const LogState();

  void togglePanel([bool? open]) {
    state = state.copyWith(isPanelOpen: open ?? !state.isPanelOpen);
  }

  void selectTab(int index) {
    state = state.copyWith(selectedTabIndex: index, isPanelOpen: true);
  }

  void logError(
    String title, {
    dynamic error,
    dynamic stackTrace,
    String? details,
    String source = 'Git',
  }) {
    final fullDetails = [
      if (details != null && details.isNotEmpty) details,
      if (error != null) error.toString(),
    ].join('\n\n');

    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: LogLevel.error,
      title: _redactSensitive(title),
      details: fullDetails.isNotEmpty ? _redactSensitive(fullDetails) : null,
      stackTrace: stackTrace != null
          ? _redactSensitive(stackTrace.toString())
          : null,
      source: source,
    );

    final updated = [entry, ...state.entries];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    state = state.copyWith(entries: updated);
  }

  void logWarning(String title, {String? details, String source = 'Git'}) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      title: _redactSensitive(title),
      details: details != null ? _redactSensitive(details) : null,
      source: source,
    );

    final updated = [entry, ...state.entries];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    state = state.copyWith(entries: updated);
  }

  void logInfo(String title, {String? details, String source = 'Git'}) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: LogLevel.info,
      title: _redactSensitive(title),
      details: details != null ? _redactSensitive(details) : null,
      source: source,
    );

    final updated = [entry, ...state.entries];
    if (updated.length > maxEntries) {
      updated.removeRange(maxEntries, updated.length);
    }
    state = state.copyWith(entries: updated);
  }

  void clear() {
    state = state.copyWith(entries: const []);
  }

  String _redactSensitive(String text) {
    // Redact HTTP credentials
    var result = text.replaceAll(
      RegExp(r'(https?://)[^:\s]+:[^@\s]+@'),
      r'$1***:***@',
    );
    // Redact common token patterns
    result = result.replaceAll(
      RegExp(r'(ghp_|github_pat_|bearer\s+)[a-zA-Z0-9_\-\.]+'),
      r'$1***REDACTED***',
    );
    return result;
  }
}

final logProvider = NotifierProvider<LogNotifier, LogState>(LogNotifier.new);
