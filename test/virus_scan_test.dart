import 'package:flutter_test/flutter_test.dart';
import 'package:threat/services/virus_scan_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('VirusScanService Tests', () {
    late Directory tempDir;

    // Known test patterns
    const eicarTestString = 'X5O!P%@AP[4\\PZX54(P^)7CC)7}';
    const suspiciousPatterns = [
      'eval(alert())',
      'system("rm -rf /")',
      'exec("format c:")',
      'powershell -Command',
      'cmd.exe /c',
      'chmod +x script.sh',
      'wget malware.com',
      '<script>alert("hack")</script>',
    ];

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('virus_scan_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<File> createTestFile(String fileName, String content) async {
      final file = File(path.join(tempDir.path, fileName));
      await file.writeAsString(content);
      return file;
    }

    test('Clean file test', () async {
      final file = await createTestFile('normal.txt', 'Hello, World!');
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, false);
      expect(result.threatName, 'Clean');
    });

    test('Suspicious extension test', () async {
      for (final ext in ['.exe', '.dll', '.bat', '.vbs']) {
        final file = await createTestFile('suspicious$ext', 'content');
        final result = await VirusScanService.scanFile(file);
        expect(result.isInfected, true,
            reason: 'Failed to detect suspicious extension: $ext');
        expect(result.threatName, contains('Suspicious file extension'));
      }
    });

    test('Suspicious filename test', () async {
      const suspiciousNames = [
        'virus_test.txt',
        'malware_sample.txt',
        'trojan_horse.txt',
        'hack_tool.txt'
      ];
      
      for (final name in suspiciousNames) {
        final file = await createTestFile(name, 'content');
        final result = await VirusScanService.scanFile(file);
        expect(result.isInfected, true,
            reason: 'Failed to detect suspicious filename: $name');
        expect(result.threatName, contains('Suspicious filename'));
      }
    });

    test('Empty file test', () async {
      final file = await createTestFile('empty.txt', '');
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, true);
      expect(result.threatName, contains('Empty file'));
    });

    test('EICAR test virus detection', () async {
      final file = await createTestFile('eicar.txt', eicarTestString);
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, true);
      expect(result.threatName, contains('EICAR test virus'));
    });

    test('Suspicious content patterns test', () async {
      for (final pattern in suspiciousPatterns) {
        final file = await createTestFile('test_${pattern.hashCode}.txt', pattern);
        final result = await VirusScanService.scanFile(file);
        expect(result.isInfected, true,
            reason: 'Failed to detect suspicious pattern: $pattern');
        expect(result.threatName, contains('Suspicious content'));
      }
    });

    test('Multiple suspicious indicators test', () async {
      final file = await createTestFile(
        'virus.exe',
        'system("rm -rf /"); eval(malicious_code);'
      );
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, true);
    });

    test('Large file handling test', () async {
      final largeContent = 'A' * 1024 * 1024; // 1MB of data
      final file = await createTestFile('large.txt', largeContent);
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, false);
      expect(result.threatName, 'Clean');
    });

    test('Error handling test', () async {
      // Create and then delete file to simulate error
      final file = await createTestFile('test.txt', '');
      await file.delete();
      
      final result = await VirusScanService.scanFile(file);
      expect(result.isInfected, false);
      expect(result.threatName, 'Scan failed');
      expect(result.error, isNotNull);
    });
  });
} 