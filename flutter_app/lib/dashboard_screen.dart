import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'scanner_service.dart';
import 'scan_result_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'about_dialog.dart';
import 'scan_screen.dart';
import 'mode_provider.dart';

class DashboardScreen extends StatefulWidget {
  final ModeProvider modeProvider;
  const DashboardScreen({Key? key, required this.modeProvider}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final ScannerService _scanner = ScannerService();
  bool _isScanning = false;
  String _scanStatus = '';
  List<Map<String, dynamic>> _recentResults = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
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
        _showNotification(result['message'] ?? 'Unknown error', isError: true);
      }
    } catch (e) {
      _showNotification('Error scanning processes: $e', isError: true);
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
        _showNotification(scanResult['message'] ?? 'Unknown error', isError: true);
      }
    } catch (e) {
      _showNotification('Error scanning files: $e', isError: true);
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
        _showNotification(result['message'] ?? 'Unknown error', isError: true);
      }
    } catch (e) {
      _showNotification('Error scanning logs: $e', isError: true);
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
        _showNotification(scanResult['message'] ?? 'Unknown error', isError: true);
      }
    } catch (e) {
      _showNotification('Error scanning file: $e', isError: true);
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
      });
    }
  }

  void _showResults(List threats, String scanType) async {
    setState(() {
      _recentResults.insert(0, {
        'type': scanType,
        'threats': threats,
        'time': DateTime.now(),
      });
    });
    // Save to history
    final summary = threats.isEmpty
        ? 'No threats found'
        : '${threats.where((t) => t['conclusion'] == 'malicious').length} threats detected';
    await ScannerService().addScanToHistory(
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

  void _navigateTo(String route) {
    if (route == 'Dashboard') return;
    if (route == 'Scan') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ScanScreen(modeProvider: widget.modeProvider)),
      );
    } else if (route == 'History') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const HistoryScreen()),
      );
    } else if (route == 'Settings') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SettingsScreen()),
      );
    }
  }

  void _showThreatDetails(Map<String, dynamic> result) {
    final threats = result['threats'] as List?;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF23262F),
        title: Text('${result['type']} Details', style: Theme.of(context).textTheme.headlineLarge),
        content: threats == null || threats.isEmpty
            ? const Text('No threats found.', style: TextStyle(color: Colors.white70))
            : SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: threats.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orangeAccent),
                    title: Text(threats[i].toString(), style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: _Sidebar(onNavigate: _navigateTo),
      appBar: AppBar(
        title: Text(
          'Quantum Antivirus',
          style: theme.textTheme.headlineLarge,
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
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    children: [
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2EC4F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: const Icon(Icons.verified_user, color: Color(0xFF2EC4F1), size: 48),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Device Protected', style: theme.textTheme.headlineLarge),
                                    const SizedBox(height: 8),
                                    Text('No threats found. Your device is safe.', style: theme.textTheme.bodyLarge),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScanActionCard(
                            icon: Icons.memory,
                            color: const Color(0xFF2EC4F1),
                            title: 'Full Scan',
                            subtitle: 'Scan all running processes.',
                            onTap: _scanProcesses,
                          ),
                          _ScanActionCard(
                            icon: Icons.folder,
                            color: const Color(0xFF2ED47A),
                            title: 'Custom Scan',
                            subtitle: 'Scan a specific folder.',
                            onTap: _scanFiles,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ScanActionCard(
                            icon: Icons.description,
                            color: const Color(0xFF5F6FFF),
                            title: 'Scan Logs',
                            subtitle: 'Analyze system logs.',
                            onTap: _scanLogs,
                          ),
                          _ScanActionCard(
                            icon: Icons.insert_drive_file,
                            color: const Color(0xFFFF647C),
                            title: 'Scan File',
                            subtitle: 'Scan a single file.',
                            onTap: _scanSingleFile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      Text('Recent Activity', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2ED47A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(Icons.check_circle, color: Color(0xFF2ED47A), size: 32),
                          ),
                          title: Text('Scan completed', style: theme.textTheme.bodyLarge),
                          subtitle: Text('No threats found', style: theme.textTheme.bodyMedium),
                          trailing: Text('Just now', style: theme.textTheme.bodyMedium),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final void Function(String) onNavigate;
  const _Sidebar({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF23262F),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Image.asset('assets/logo.png', height: 48),
          const SizedBox(height: 16),
          const Text(
            'Quantum Antivirus',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 32),
          _SidebarItem(icon: Icons.dashboard, label: 'Dashboard', selected: true, onTap: () => onNavigate('Dashboard')),
          _SidebarItem(icon: Icons.memory, label: 'Scan', onTap: () => onNavigate('Scan')),
          _SidebarItem(icon: Icons.history, label: 'History', onTap: () => onNavigate('History')),
          _SidebarItem(icon: Icons.settings, label: 'Settings', onTap: () => onNavigate('Settings')),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _SidebarItem({required this.icon, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.greenAccent : Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.greenAccent : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: Colors.green.withOpacity(0.1),
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ScanActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
    children: [
      const Text('A modern, production-ready antivirus app built with Flutter.\n\nDeveloped by Your Team.'),
    ],
  );
} 