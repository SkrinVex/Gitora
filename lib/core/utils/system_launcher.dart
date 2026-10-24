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

  static Future<void> openInTerminal(String path) async {
    if (Platform.isWindows) {
      // Windows Terminal if available, else powershell / cmd
      try {
        await Process.run('wt.exe', ['-d', path]);
      } catch (_) {
        Process.start('powershell.exe', [
          '-NoExit',
          '-Command',
          'Set-Location "$path"',
        ]);
      }
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-a', 'Terminal', path]);
    } else if (Platform.isLinux) {
      await Process.run('x-terminal-emulator', ['--working-directory=$path']);
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
