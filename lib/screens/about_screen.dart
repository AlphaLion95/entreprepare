// Create folder if missing: c:\flutter_projects\entreprepare\lib\screens\settings
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('App name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              SizedBox(height: 12),
              Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Put details about this app here.'),
            ]),
          ),
        ),
      ]),
    );
  }
}