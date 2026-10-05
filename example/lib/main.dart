import 'package:flutter/material.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

void main() {
  runApp(const QrScannerExampleApp());
}

/// Example application for `qr_scanner_kit`.
class QrScannerExampleApp extends StatelessWidget {
  /// Creates the example application.
  const QrScannerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'qr_scanner_kit example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF9BD41E),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

/// Home page that shows the last scanned value and opens the scanner.
class ExampleHomePage extends StatefulWidget {
  /// Creates the example home page.
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  String _lastScan = 'No scan yet';

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return QrScanner(
            title: 'Scan QR code',
            onScan: (String value) {
              setState(() {
                _lastScan = value;
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('qr_scanner_kit example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Last scan: $_lastScan', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Open scanner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
