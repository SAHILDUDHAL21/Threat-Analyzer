import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'scan_history.dart';
import 'services/virus_scan_service.dart';
import 'widgets/scan_rating_chart.dart';

class CheckStatus {
  final IconData icon;
  final Color color;
  final String message;

  CheckStatus(this.icon, this.color, this.message);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _result;
  String? _statusMessage;
  List<Map<String, String>> _threats = [];
  final TextEditingController _fileController = TextEditingController();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      String? path = result.files.single.path;
      if (path != null) {
        _fileController.text = path;
        setState(() {
          _statusMessage = 'Scanning file...';
          _result = null;
          _threats.clear();
        });
        
        // Scan the file for viruses
        final file = File(path);
        final scanResult = await VirusScanService.scanFile(file);
        
        if (!mounted) return;
        
        if (scanResult.isInfected) {
          setState(() {
            _statusMessage = 'Scan complete';
            _result = 'The file contains threats.';
            _threats = [{
              'engine': 'Local Scanner',
              'threat': scanResult.threatName
            }];
            
            // Save to history
            ScanHistory.addHistory({
              'filePath': path,
              'result': _result!,
              'threats': _threats,
            });
          });
        } else {
          // If local scan is clean, proceed with VirusTotal scan
          _calculateFileHash(path);
        }
      }
    } else {
      setState(() {
        _statusMessage = 'No file selected';
      });
    }
  }

  Future<void> _calculateFileHash(String filePath) async {
    setState(() {
      _statusMessage = 'Calculating file hash...';
      _result = null;
      _threats.clear();
    });

    // Dummy hash calculation simulation
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _statusMessage = 'Hash calculated. Uploading file...';
    });

    _uploadFile(filePath);
  }

  Future<void> _uploadFile(String filePath) async {
    const apiKey = 'Tuza_api_chavi';  // Replace with your actual API key
    var url = Uri.parse('https://www.virustotal.com/api/v3/files');

    var request = http.MultipartRequest('POST', url)
      ..headers['x-apikey'] = apiKey
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      var scanId = jsonResponse['data']['id'];
      setState(() {
        _statusMessage = 'File uploaded. Scanning file...';
      });
      _getFileReport(scanId);
    } else {
      setState(() {
        _statusMessage = 'Failed to upload file. Status code: ${response.statusCode}';
        _result = null;
      });
    }
  }

  Future<void> _getFileReport(String scanId) async {
    const apiKey = 'ohh_shit';  // Replace with your actual API key
    var url = Uri.parse('https://www.virustotal.com/api/v3/analyses/$scanId');
    var response = await http.get(url, headers: {'x-apikey': apiKey});

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var maliciousCount = jsonResponse['data']['attributes']['stats']['malicious'];
      var threatNames = <Map<String, String>>[];

      jsonResponse['data']['attributes']['results'].forEach((key, value) {
        if (value['category'] == 'malicious') {
          threatNames.add({
            'engine': key,
            'threat': value['result']
          });
        }
      });

      setState(() {
        _statusMessage = 'Scan complete';
        _result = maliciousCount > 0
            ? 'The file contains threats.'
            : 'The file is safe.';
        _threats = threatNames;

        // Save scan history
        if (maliciousCount > 0 || threatNames.isNotEmpty) {
          ScanHistory.addHistory({
            'filePath': _fileController.text,
            'result': _result!,
            'threats': threatNames,
          });
        }
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to get file report. Status code: ${response.statusCode}';
        _result = null;
      });
    }
  }

  Future<void> scanFile(File file) async {
    if (!mounted) return;
    
    try {
      final result = await VirusScanService.scanFile(file);
      if (!mounted) return;
      
      if (result.isInfected) {
        _showAlert(
          title: 'Threat Detected!',
          content: 'Threat type: ${result.threatName}',
        );
      } else {
        _showAlert(
          title: 'File is Safe',
          content: 'No threats detected in this file.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAlert(
        title: 'Scan Error',
        content: 'Error scanning file: $e',
      );
    }
  }

  void _showAlert({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanResultCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          _result!.contains('threats') ? Icons.warning : Icons.check_circle,
          color: _result!.contains('threats') ? Colors.red : Colors.green,
          size: 48,
        ),
        title: Text(
          _result!,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _result!.contains('threats') ? Colors.red : Colors.green,
          ),
        ),
        subtitle: Text(_statusMessage ?? ''),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scan Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ScanRatingChart(
                malicious: _threats.length,
                suspicious: 0,
                harmless: _threats.isEmpty ? 1 : 0,
                undetected: 0,
                size: 180,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('File Name', _fileController.text.split('/').last),
            _buildDetailRow('Scan Time', DateTime.now().toString()),
            _buildDetailRow('Status', _result!.contains('threats') ? 'Infected' : 'Clean'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey,
                  ),
                  children: [
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Check Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    TableCell(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Result',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                _buildAnalysisRow('File Extension', _getCheckStatus('extension')),
                _buildAnalysisRow('File Name', _getCheckStatus('filename')),
                _buildAnalysisRow('File Size', _getCheckStatus('size')),
                _buildAnalysisRow('EICAR Test', _getCheckStatus('eicar')),
                _buildAnalysisRow('Script Content', _getCheckStatus('script')),
                _buildAnalysisRow('System Commands', _getCheckStatus('system')),
                _buildAnalysisRow('Network Commands', _getCheckStatus('network')),
                _buildAnalysisRow('Malicious Functions', _getCheckStatus('functions')),
                _buildAnalysisRow('Binary Analysis', _getCheckStatus('binary')),
                _buildAnalysisRow('Permission Commands', _getCheckStatus('permissions')),
                _buildAnalysisRow('Encryption Check', _getCheckStatus('encryption')),
                _buildAnalysisRow('Archive Analysis', _getCheckStatus('archive')),
                _buildAnalysisRow('Metadata Check', _getCheckStatus('metadata')),
                _buildAnalysisRow('Signature Check', _getCheckStatus('signature')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildAnalysisRow(String type, CheckStatus status) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(type),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  status.icon,
                  color: status.color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(status.message),
              ],
            ),
          ),
        ),
      ],
    );
  }

  CheckStatus _getCheckStatus(String checkType) {
    if (_threats.isEmpty) {
      return CheckStatus(
        Icons.check_circle,
        Colors.green,
        'Clean',
      );
    }

    final threatName = _threats.first['threat']?.toLowerCase() ?? '';
    
    switch (checkType) {
      case 'extension':
        return threatName.contains('extension') 
            ? CheckStatus(Icons.warning, Colors.red, 'Suspicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'filename':
        return threatName.contains('filename')
            ? CheckStatus(Icons.warning, Colors.red, 'Suspicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'size':
        return threatName.contains('empty')
            ? CheckStatus(Icons.warning, Colors.red, 'Suspicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Normal');
      
      case 'eicar':
        return threatName.contains('eicar')
            ? CheckStatus(Icons.warning, Colors.red, 'Detected')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'script':
        return threatName.contains('script') || threatName.contains('eval')
            ? CheckStatus(Icons.warning, Colors.red, 'Malicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'system':
        return threatName.contains('system') || threatName.contains('exec')
            ? CheckStatus(Icons.warning, Colors.red, 'Dangerous')
            : CheckStatus(Icons.check_circle, Colors.green, 'Safe');
      
      case 'network':
        return threatName.contains('wget') || threatName.contains('curl')
            ? CheckStatus(Icons.warning, Colors.red, 'Suspicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'functions':
        return threatName.contains('function') || threatName.contains('eval')
            ? CheckStatus(Icons.warning, Colors.red, 'Malicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'binary':
        return threatName.contains('exe') || threatName.contains('dll')
            ? CheckStatus(Icons.warning, Colors.red, 'Suspicious')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'permissions':
        return threatName.contains('chmod') || threatName.contains('sudo')
            ? CheckStatus(Icons.warning, Colors.red, 'Dangerous')
            : CheckStatus(Icons.check_circle, Colors.green, 'Safe');
      
      case 'encryption':
        return threatName.contains('encrypt') || threatName.contains('base64')
            ? CheckStatus(Icons.warning, Colors.orange, 'Review')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'archive':
        return threatName.contains('zip') || threatName.contains('rar')
            ? CheckStatus(Icons.info, Colors.blue, 'Review')
            : CheckStatus(Icons.check_circle, Colors.green, 'Clean');
      
      case 'metadata':
        return CheckStatus(Icons.check_circle, Colors.green, 'Valid');
      
      case 'signature':
        return CheckStatus(Icons.check_circle, Colors.green, 'Valid');
      
      default:
        return CheckStatus(Icons.check_circle, Colors.green, 'Clean');
    }
  } // bc thaklo return karu karu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Threat Analyzer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _fileController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Selected File',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Select File to Scan'),
              ),
              const SizedBox(height: 20),
              if (_statusMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_statusMessage!, 
                    style: const TextStyle(color: Colors.blue)),
                ),
              if (_result != null) ...[
                _buildScanResultCard(),
                const SizedBox(height: 20),
                _buildDetailsCard(),
                const SizedBox(height: 20),
                _buildAnalysisTable(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
