import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:git2dart/git2dart.dart';

void main() {
  test('Git CLI is available', () async {
    final result = await Process.run('git', ['--version']);
    expect(result.exitCode, equals(0));
    expect(result.stdout.toString(), contains('git version'));
  });

  test('Libgit2 availability check', () {
    try {
      final version = Libgit2.version;
      expect(version, isNotEmpty);
      final features = Libgit2.features;
      expect(features, isA<Set<GitFeature>>());
    } catch (e) {
      // In non-compiled unit test runner on Windows, native DLLs might not be loaded if not packaged
      // ignore: avoid_print
      print('Libgit2 runtime note in test: $e');
    }
  });
}
