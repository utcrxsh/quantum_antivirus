import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scanner_service.dart';
import 'scan_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final scannerService = ScannerService();
    final history = await scannerService.getScanHistory();
    setState(() {
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark ? theme.textTheme.headlineLarge?.color : Colors.white,
          ),
        ),
      ),
      body: _history.isEmpty
          ? Center(
              child: Text('No scan history yet.', style: theme.textTheme.headlineMedium),
            )
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final entry = _history[index];
                final dt = DateTime.tryParse(entry['timestamp'] ?? '') ?? DateTime.now();
                final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text('${entry['scanType']} - $formattedTime', style: theme.textTheme.bodyLarge),
                    subtitle: Text(entry['summary'] ?? '', style: theme.textTheme.bodyMedium),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScanResultScreen(
                            threats: entry['threats'] ?? [],
                            scanType: entry['scanType'] ?? 'Scan',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 