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
      final pref = preferredTerminal?.toLowerCase().trim();

      Future<bool> tryLaunch(String executable, List<String> startArgs) async {
        try {
          final process = await Process.start(
            'cmd.exe',
            ['/c', 'start', '', executable, ...startArgs],
            workingDirectory: cleanPath,
            mode: ProcessStartMode.detached,
          );
          return process.pid > 0;
        } catch (_) {
          return false;
        }
      }

      Future<bool> hasWt() async {
        try {
          final check = await Process.run('where.exe', ['wt.exe']);
          return check.exitCode == 0;
        } catch (_) {
          return false;
        }
      }

      final escapedForPs = cleanPath.replaceAll("'", "''");

      // 1. User preferred terminal from settings (if specified and not 'auto')
      if (pref != null && pref.isNotEmpty && pref != 'auto') {
        if (pref == 'wt' || pref == 'windowsterminal') {
          if (await hasWt()) {
            final ok = await tryLaunch('wt.exe', ['-d', cleanPath]);
            if (ok) return;
          }
        } else if (pref == 'powershell' || pref == 'pwsh') {
          final ok = await tryLaunch('powershell.exe', [
            '-NoExit',
            '-Command',
            "Set-Location -LiteralPath '$escapedForPs'",
          ]);
          if (ok) return;
        } else if (pref == 'cmd') {
          final ok = await tryLaunch('cmd.exe', ['/k', 'cd /d "$cleanPath"']);
          if (ok) return;
        } else {
          // Custom terminal executable path/name
          final ok = await tryLaunch(pref, []);
          if (ok) return;
        }
      }

      // 2. Windows Terminal if available
      if (await hasWt()) {
        final ok = await tryLaunch('wt.exe', ['-d', cleanPath]);
        if (ok) return;
      }

      // 3. PowerShell default
      final okPs = await tryLaunch('powershell.exe', [
        '-NoExit',
        '-Command',
        "Set-Location -LiteralPath '$escapedForPs'",
      ]);
      if (okPs) return;

      // 4. Command Prompt fallback
      final okCmd = await tryLaunch('cmd.exe', ['/k', 'cd /d "$cleanPath"']);
      if (okCmd) return;

      throw Exception(
        'Failed to launch Windows terminal: all candidates (wt.exe, powershell.exe, cmd.exe) failed.',
      );
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
