import 'package:flutter/material.dart';
import 'services/virus_scan_service.dart';

class ScanResultPage extends StatelessWidget {
  final ScanResult result;
  final String fileName;

  const ScanResultPage({
    super.key,
    required this.result,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              _buildDetailsCard(),
              const SizedBox(height: 20),
              _buildAnalysisTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: ListTile(
        leading: Icon(
          result.isInfected ? Icons.warning : Icons.check_circle,
          color: result.isInfected ? Colors.red : Colors.green,
          size: 48,
        ),
        title: Text(
          result.isInfected ? 'Threat Detected!' : 'File is Safe',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: result.isInfected ? Colors.red : Colors.green,
          ),
        ),
        subtitle: Text(result.threatName),
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
            const SizedBox(height: 10),
            _buildDetailRow('File Name', fileName),
            _buildDetailRow('Scan Time', 
              '${result.scanTime.hour}:${result.scanTime.minute}:${result.scanTime.second}'),
            _buildDetailRow('Status', result.isInfected ? 'Infected' : 'Clean'),
            if (result.error != null)
              _buildDetailRow('Error', result.error!),
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
              'Threat Analysis',
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
                _buildTableRow('File Extension', _getExtensionStatus()),
                _buildTableRow('File Name', _getFilenameStatus()),
                _buildTableRow('File Size', _getFileSizeStatus()),
                _buildTableRow('Content Analysis', _getContentStatus()),
                _buildTableRow('EICAR Test', _getEicarStatus()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String type, String status) {
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
                  status == 'Clean' ? Icons.check_circle : Icons.warning,
                  color: status == 'Clean' ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(status),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getExtensionStatus() {
    if (result.threatName.contains('file extension')) {
      return 'Suspicious';
    }
    return 'Clean';
  }

  String _getFilenameStatus() {
    if (result.threatName.contains('filename')) {
      return 'Suspicious';
    }
    return 'Clean';
  }

  String _getFileSizeStatus() {
    if (result.threatName.contains('Empty file')) {
      return 'Suspicious';
    }
    return 'Clean';
  }

  String _getContentStatus() {
    if (result.threatName.contains('Suspicious content')) {
      return 'Malicious';
    }
    return 'Clean';
  }

  String _getEicarStatus() {
    if (result.threatName.contains('EICAR')) {
      return 'Detected';
    }
    return 'Clean';
  }
} 