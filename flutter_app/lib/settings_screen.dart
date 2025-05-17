import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _systemInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSystemInfo();
  }

  Future<void> _fetchSystemInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    Map<String, String> info = {};
    try {
      if (Platform.isWindows) {
        final windows = await deviceInfo.windowsInfo;
        info['OS'] = 'Windows';
        info['Computer Name'] = windows.computerName ?? 'Unknown';
        info['Number of Cores'] = windows.numberOfCores?.toString() ?? 'Unknown';
        info['User Name'] = windows.userName ?? 'Unknown';
      } else if (Platform.isLinux) {
        final linux = await deviceInfo.linuxInfo;
        info['OS'] = 'Linux';
        info['Name'] = linux.name ?? 'Unknown';
        info['Version'] = linux.version ?? 'Unknown';
        info['Machine ID'] = linux.machineId ?? 'Unknown';
      } else if (Platform.isMacOS) {
        final mac = await deviceInfo.macOsInfo;
        info['OS'] = 'macOS';
        info['Computer Name'] = mac.computerName ?? 'Unknown';
        info['Model'] = mac.model ?? 'Unknown';
      } else {
        info['OS'] = Platform.operatingSystem;
      }
    } catch (e) {
      info['Error'] = 'Failed to fetch system info: $e';
    }
    setState(() {
      _systemInfo = info;
      _isLoading = false;
    });
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
              'Settings',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark ? theme.textTheme.headlineLarge?.color : Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text('System Information', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _systemInfo.entries.map((entry) => ListTile(
                              leading: const Icon(Icons.computer),
                              title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(entry.value),
                            )).toList(),
                          ),
                    const SizedBox(height: 32),
                    Text('About Quantum Antivirus', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.verified_user, color: Color(0xFF2EC4F1)),
                      title: const Text('Quantum Antivirus'),
                      subtitle: const Text('Version 1.0.0'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.green),
                      title: const Text('A modern, production-ready antivirus app built with Flutter.'),
                      subtitle: const Text('Developed by GameOver.'),
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