import 'dart:io';

class SystemLauncher {
  static Future<void> openInExplorer(String path) async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  }

  static Future<void> openInTerminal(
    String path, {
    String? preferredTerminal,
  }) async {
    final cleanPath = path.replaceAll('/', '\\');

    if (Platform.isWindows) {
      final pref = preferredTerminal?.toLowerCase();

      // 1. Windows Terminal if explicitly requested or auto
      if (pref == 'wt' ||
          pref == 'windowsterminal' ||
          pref == 'auto' ||
          pref == null) {
        try {
          final check = await Process.run('where.exe', ['wt.exe']);
          if (check.exitCode == 0) {
            await Process.start(
              'wt.exe',
              ['-d', cleanPath],
              workingDirectory: cleanPath,
              mode: ProcessStartMode.detached,
            );
            return;
          }
        } catch (_) {}
      }

      // 2. PowerShell (default on Windows or fallback)
      if (pref != 'cmd') {
        try {
          await Process.start(
            'powershell.exe',
            ['-NoExit', '-Command', "Set-Location -LiteralPath '$cleanPath'"],
            workingDirectory: cleanPath,
            mode: ProcessStartMode.detached,
          );
          return;
        } catch (_) {}
      }

      // 3. Command Prompt fallback
      try {
        await Process.start(
          'cmd.exe',
          ['/k', 'cd /d "$cleanPath"'],
          workingDirectory: cleanPath,
          mode: ProcessStartMode.detached,
        );
        return;
      } catch (e) {
        throw Exception('Failed to launch Windows terminal: $e');
      }
    } else if (Platform.isLinux) {
      final pref = preferredTerminal?.trim();
      final candidates = <List<String>>[
        if (pref != null && pref.isNotEmpty && pref != 'auto') [pref, path],
        ['xdg-terminal-exec', path],
        ['gnome-terminal', '--working-directory=$path'],
        ['konsole', '--workdir', path],
        ['kitty', '--directory', path],
        ['alacritty', '--working-directory', path],
        ['x-terminal-emulator', '--working-directory=$path'],
        ['xterm', '-e', 'cd "$path" && \$SHELL'],
      ];

      for (final candidate in candidates) {
        try {
          final cmd = candidate.first;
          final args = candidate.sublist(1);
          final res = await Process.run('which', [cmd]);
          if (res.exitCode == 0) {
            await Process.start(
              cmd,
              args,
              workingDirectory: path,
              mode: ProcessStartMode.detached,
            );
            return;
          }
        } catch (_) {}
      }
      throw Exception(
        'No supported Linux terminal found. Please set your preferred terminal in Settings.',
      );
    } else if (Platform.isMacOS) {
      try {
        await Process.start(
          'open',
          ['-a', 'Terminal', path],
          workingDirectory: path,
          mode: ProcessStartMode.detached,
        );
      } catch (e) {
        throw Exception('Failed to launch macOS terminal: $e');
      }
    }
  }

  static Future<void> openInVSCode(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd.exe', ['/c', 'code', path]);
      } else {
        await Process.run('code', [path]);
      }
    } catch (_) {}
  }
}
