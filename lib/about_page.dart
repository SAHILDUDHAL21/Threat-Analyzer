import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(String urlString) async {
    try {
      if (!await launchUrlString(urlString)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  Widget _buildDeveloperCard(BuildContext context, {
    required String name,
    required String linkedIn,
    required String github,
    required String description,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Developer: $name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Image.asset('assets/linkedin.png', width: 24, height: 24),
                  onPressed: () => _launchUrl(linkedIn),
                  tooltip: 'LinkedIn Profile',
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Image.asset('assets/github.png', width: 24, height: 24),
                  onPressed: () => _launchUrl(github),
                  tooltip: 'GitHub Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildDeveloperCard(
              context,
              name: 'Sahil Dudhal',
              linkedIn: 'https://linkedin.com/in/sahil-dudhal-1b11b925a',
              github: 'https://github.com/SAHILDUDHAL21',
              description: 'Computer Science Student | Programmer | Developer | Linux Enthusiast',
            ),
            const SizedBox(height: 20),
            const Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Threat Analyzer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '© 2024 All Rights Reserved',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
