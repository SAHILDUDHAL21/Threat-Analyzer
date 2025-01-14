import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class VirusScanService {
  static const platform = MethodChannel('com.your.app/virus_scan');
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        await platform.invokeMethod('initializeScanner');
        _initialized = true;
      } catch (e) {
        debugPrint('Failed to initialize virus scanner: $e');
      }
    }
  }

  static Future<ScanResult> scanFile(File file) async {
    if (file.existsSync() == false) {
      return ScanResult(
        isInfected: false,
        threatName: 'File not found',
        scanTime: DateTime.now(),
        error: 'File does not exist',
        engineResults: [],
        stats: ScanStats(
          malicious: 0,
          suspicious: 0,
          clean: 0,
          undetected: 0,
          total: 0,
        ),
      );
    }

    try {
      final results = <EngineResult>[];
      final String content = await _readFileContent(file);
      
      // Add all antivirus engines (20+ engines) 10 ch free api madhe chalta
      final engines = [
        'Kaspersky', 'BitDefender', 'Symantec', 'McAfee', 'ClamAV',
        'Avast', 'AVG', 'Microsoft', 'TrendMicro', 'Sophos',
        'ESET-NOD32', 'F-Secure', 'Avira', 'Comodo', 'DrWeb',
        'Fortinet', 'GData', 'Ikarus', 'K7AntiVirus', 'Malwarebytes',
        'Panda', 'QuickHeal', 'VBA32', 'ViRobot', 'Zillya'
      ];

      // Check with each engine
      for (final engine in engines) {
        results.add(_checkAntivirus(engine, file, content));
      }

      int maliciousCount = results.where((r) => r.isInfected).length;
      int suspiciousCount = results.where((r) => r.isSuspicious).length;
      int cleanCount = results.where((r) => !r.isInfected && !r.isSuspicious).length;
      int undetectedCount = results.where((r) => r.isUndetected).length;

      return ScanResult(
        isInfected: maliciousCount > 0,
        threatName: _determineThreatName(results),
        scanTime: DateTime.now(),
        engineResults: results,
        stats: ScanStats(
          malicious: maliciousCount,
          suspicious: suspiciousCount,
          clean: cleanCount,
          undetected: undetectedCount,
          total: results.length,
        ),
      );
    } catch (e) {
      debugPrint('Scan failed: $e');
      return ScanResult(
        isInfected: false,
        threatName: 'Scan failed',
        scanTime: DateTime.now(),
        error: e.toString(),
        engineResults: [],
        stats: ScanStats(
          malicious: 0,
          suspicious: 0,
          clean: 0,
          undetected: 0,
          total: 0,
        ),
      );
    }
  }

  static Future<String> _readFileContent(File file) async {
    final List<int> bytes = await file.openRead(0, 4096).first;
    return String.fromCharCodes(bytes);
  }

  static String _determineThreatName(List<EngineResult> results) {
    final maliciousResults = results.where((r) => r.isInfected);
    if (maliciousResults.isEmpty) return 'Clean';
    
    // Return the most common threat name = ux designer- cha bhosda (tyla sangu sangu thaklo insta nahi ne animation dyla)
    final threatCounts = <String, int>{};
    for (var result in maliciousResults) {
      threatCounts[result.result] = (threatCounts[result.result] ?? 0) + 1;
    }
    
    return threatCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b) // if esle peksha br ahe 
        .key;
  }

  static EngineResult _checkAntivirus(String engine, File file, String content) {
    // Simulate different engine behaviors with more varied responses
    // he khalcha line la tan du nay lay bhand zaloy me
    if (content.contains('X5O!P%@AP[4\\PZX54(P^)7CC)7}')) {
      return EngineResult(
        engine: engine,
        result: 'EICAR-Test-File',
        category: 'malicious',
      );
    }

    if (_containsSuspiciousPatterns(content)) {
      // Randomize some responses to simulate real-world behavior
      final random = DateTime.now().millisecondsSinceEpoch % 3;
      switch (random) {
        case 0:
          return EngineResult(
            engine: engine,
            result: 'Suspicious.Script',
            category: 'suspicious',
          );
        case 1:
          return EngineResult(
            engine: engine,
            result: 'PUA.Generic.Risk',
            category: 'suspicious',
          );
        default:
          return EngineResult(
            engine: engine,
            result: 'Clean',
            category: 'clean',
          );
      }
    }

    return EngineResult(
      engine: engine,
      result: 'Clean',
      category: 'clean',
    );
  }

  static bool _containsSuspiciousPatterns(String content) {
    final suspiciousPatterns = [
      'eval(', 'system(', 'exec(', 'powershell',
      'cmd.exe', 'chmod +x', 'rm -rf', 'format c:',
      'del /f', 'wget ', 'curl ', '<script>',
      'function()', '.vbs', '.bat', '.sh',
      'sudo ', 'base64_decode'
    ];

    return suspiciousPatterns.any((pattern) =>
      content.toLowerCase().contains(pattern.toLowerCase()));
  }
}

class ScanResult {
  final bool isInfected;
  final String threatName;
  final DateTime scanTime;
  final String? error;
  final List<EngineResult> engineResults;
  final ScanStats stats;

  ScanResult({
    required this.isInfected,
    required this.threatName,
    required this.scanTime,
    this.error,
    required this.engineResults,
    required this.stats,
  });
}

class EngineResult {
  final String engine;
  final String result;
  final String category;

  EngineResult({
    required this.engine,
    required this.result,
    required this.category,
  });

  bool get isInfected => category == 'malicious';
  bool get isSuspicious => category == 'suspicious';
  bool get isUndetected => category == 'undetected';
}

class ScanStats {
  final int malicious;
  final int suspicious;
  final int clean;
  final int undetected;
  final int total;

  ScanStats({
    required this.malicious,
    required this.suspicious,
    required this.clean,
    required this.undetected,
    required this.total,
  });
} 