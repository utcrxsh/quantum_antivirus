import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScannerService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<Map<String, dynamic>> scanProcesses() async {
    final response = await http.get(Uri.parse('$baseUrl/scan_processes?mode=quantum'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to scan processes: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> scanLogs() async {
    final response = await http.get(Uri.parse('$baseUrl/scan_logs?mode=quantum'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to scan logs: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> scanFiles(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scan_files?path=${Uri.encodeComponent(path)}&mode=quantum'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to scan files: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> scanSingleFile(String filePath) async {
    var uri = Uri.parse('$baseUrl/scan_file?mode=quantum');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    request.fields['original_path'] = filePath;
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to scan file: ${response.body}');
    }
  }

  // --- History helpers ---
  Future<void> addScanToHistory({
    required String scanType,
    required String summary,
    required List threats,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('scan_history') ?? [];
    final entry = json.encode({
      'scanType': scanType,
      'timestamp': DateTime.now().toIso8601String(),
      'summary': summary,
      'threats': threats,
    });
    history.insert(0, entry); // Most recent first
    await prefs.setStringList('scan_history', history);
  }

  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('scan_history') ?? [];
    return history.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }
} 