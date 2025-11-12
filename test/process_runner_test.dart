import 'dart:io';

import 'package:test/test.dart';
import 'package:pubmind/utils/process_runner.dart';

void main() {
  group('ProcessRunner', () {
    late ProcessRunner processRunner;

    setUp(() {
      processRunner = ProcessRunner(workingDirectory: '.', verbose: true);
    });

    test('should identify a Flutter project', () async {
      // Create a mock pubspec.yaml for a Flutter project
      final pubspecContent = 'name: test_project\nversion: 1.0.0\nflutter: \n';
      File('${processRunner.workingDirectory}/pubspec.yaml')
          .writeAsStringSync(pubspecContent);

      expect(processRunner.isFlutterProject, isTrue);

      expect(processRunner.isFlutterProject, isTrue);
    });

    test('should identify a non-Flutter project', () async {
      // Create a mock pubspec.yaml for a non-Flutter project
      final pubspecContent = 'name: test_project\nversion: 1.0.0\n';
      File('${processRunner.workingDirectory}/pubspec.yaml')
          .writeAsStringSync(pubspecContent);

      expect(processRunner.isFlutterProject, isFalse);
    });
    test('should run pub get command', () async {
      final result = await processRunner.pubGet();
      expect(result.exitCode, equals(0)); // Assuming pub get succeeds
    });

    test('should run pub add command', () async {
      final result = await processRunner.pubAdd('http');
      expect(result.exitCode, equals(0)); // Assuming pub add succeeds
    });

    test('should run pub remove command', () async {
      final result = await processRunner.pubRemove('http');
      expect(result.exitCode, equals(0)); // Assuming pub remove succeeds
    });

    test('should run dart analyze command', () async {
      final result = await processRunner.dartAnalyze();
      expect(result.exitCode, equals(0)); // Assuming dart analyze succeeds
    });

    test('should return error for non-Flutter project', () async {
      // Mock a non-Flutter project
      // Example: await createMockPubspec(isFlutter: false);

      final result = await processRunner.flutterClean();
      expect(result.exitCode, equals(1)); // Expecting error exit code
      expect(result.stderr, contains('Not a Flutter project'));
    });
  });
}
