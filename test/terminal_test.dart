import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitora/core/utils/system_launcher.dart';

void main() {
  test('Terminal launch with spaces and Unicode on Windows/Linux', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'gitora terminal test кириллица ',
    );
    try {
      expect(tempDir.existsSync(), isTrue);

      // Verify openInTerminal launches without throwing
      await SystemLauncher.openInTerminal(
        tempDir.path,
        preferredTerminal: 'powershell',
      );
    } finally {
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {
        // Windows may hold working directory lock while terminal process runs
      }
    }
  });
}
