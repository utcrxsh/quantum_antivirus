import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'scanner_service.dart';
import 'scan_result_screen.dart';
import 'about_dialog.dart';
import 'package:http/http.dart' as http;
import 'mode_provider.dart';

class ScanScreen extends StatefulWidget {
  final ModeProvider modeProvider;
  const ScanScreen({Key? key, required this.modeProvider}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScannerService _scanner = ScannerService();
  bool _isScanning = false;
  String _scanStatus = '';

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _scanProcesses() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning processes...';
    });
    try {
      final result = await _scanner.scanProcesses();
      if (result['status'] == 'success') {
        _showResults(result['threats'], 'Process Scan');
      } else {
        _showError(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showError('Error scanning processes: $e');
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
    }
  }

  Future<void> _scanFiles() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning files...';
    });
    try {
      final scanResult = await _scanner.scanFiles(result);
      if (scanResult['status'] == 'success') {
        _showResults(scanResult['threats'], 'File Scan');
      } else {
        _showError(scanResult['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showError('Error scanning files: $e');
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
    }
  }

  Future<void> _scanLogs() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning system logs...';
    });
    try {
      final result = await _scanner.scanLogs();
      if (result['status'] == 'success') {
        _showResults(result['threats'], 'Log Scan');
      } else {
        _showError(result['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showError('Error scanning logs: $e');
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
    }
  }

  Future<void> _scanSingleFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning file...';
    });
    try {
      final scanResult = await _scanner.scanSingleFile(result.files.single.path!);
      if (scanResult['status'] == 'success') {
        _showResults(scanResult['threats'], 'Single File Scan');
      } else {
        _showError(scanResult['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showError('Error scanning file: $e');
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
    }
  }

  void _showResults(List threats, String scanType) async {
    // Save to history
    final summary = threats.isEmpty
        ? 'No threats found'
        : '${threats.where((t) => t['conclusion'] == 'malicious').length} threats detected';
    final scannerService = ScannerService();
    await scannerService.addScanToHistory(
      scanType: scanType,
      summary: summary,
      threats: threats,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(threats: threats, scanType: scanType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            Text(
              'Scan',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Icon(Icons.bolt, color: theme.colorScheme.primary, size: 28),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => showAboutDialogCustom(context),
                tooltip: 'About',
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: _isScanning
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                            strokeWidth: 6,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(_scanStatus, style: theme.textTheme.headlineMedium),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ScanOptionCard(
                            icon: Icons.memory,
                            color: const Color(0xFF2EC4F1),
                            title: 'Scan Processes',
                            subtitle: 'Detect threats in running processes.',
                            onTap: _scanProcesses,
                          ),
                          _ScanOptionCard(
                            icon: Icons.folder,
                            color: const Color(0xFF2ED47A),
                            title: 'Scan Files',
                            subtitle: 'Scan all files in a folder for malware.',
                            onTap: _scanFiles,
                          ),
                          _ScanOptionCard(
                            icon: Icons.description,
                            color: const Color(0xFF5F6FFF),
                            title: 'Scan System Logs',
                            subtitle: 'Analyze system logs for suspicious activity.',
                            onTap: _scanLogs,
                          ),
                          _ScanOptionCard(
                            icon: Icons.insert_drive_file,
                            color: const Color(0xFFFF647C),
                            title: 'Scan a File',
                            subtitle: 'Scan a single file for threats.',
                            onTap: _scanSingleFile,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ScanOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showAboutDialogCustom(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Quantum Antivirus',
    applicationVersion: '1.0.0',
    applicationIcon: Image.asset('assets/logo.png', height: 48),
    children: [
      const Text('A modern, production-ready antivirus app built with Flutter.\n\nDeveloped by Your Team.'),
    ],
  );
}