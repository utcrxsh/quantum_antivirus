import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScanResultScreen extends StatelessWidget {
  final List threats;
  final String scanType;
  const ScanResultScreen({Key? key, required this.threats, required this.scanType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('$scanType Results', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF181A20),
      body: threats.isEmpty
          ? const Center(
              child: Text('No threats found.', style: TextStyle(color: Colors.white70, fontSize: 18)),
            )
          : ListView.builder(
              itemCount: threats.length,
              itemBuilder: (context, index) => buildThreatTile(context, threats[index]),
            ),
    );
  }

  Widget buildThreatTile(BuildContext context, Map<String, dynamic> threat) {
    final double threatScore = (threat['threat_score'] as num?)?.toDouble() ?? 0.0;
    final String scanType = threat['scan_type'] ?? '';
    final String timestamp = threat['timestamp'] ?? '';
    final List featureVector = threat['feature_vector'] ?? [];
    final String conclusion = threat['conclusion'] ?? 'benign';

    // Extract process/file/log info
    final String? processName = threat['process_name'];
    final int? pid = threat['pid'];
    final String? fileName = threat['file_name'];
    final String? filePath = threat['file_path'];
    final int? eventId = threat['event_id'];
    final int? eventType = threat['event_type'];
    final String? sourceName = threat['source_name'];
    final String? timeGenerated = threat['time_generated'];
    final String? eventCategory = threat['event_category']?.toString();
    final String? eventData = threat['event_data'];
    final String? stringInserts = threat['string_inserts'];

    // Format timestamp
    String formattedTime = timestamp;
    try {
      final dt = DateTime.parse(timestamp);
      formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {}

    // Color and label based on conclusion
    Color scoreColor;
    String severity;
    IconData severityIcon;
    if (conclusion == 'malicious') {
      scoreColor = Colors.red;
      severity = "Malicious";
      severityIcon = Icons.dangerous;
    } else {
      scoreColor = Colors.green;
      severity = "Benign";
      severityIcon = Icons.verified_user;
    }

    // Compose extra info for subtitle
    String extraInfo = '';
    if (scanType == 'process') {
      extraInfo = 'Process: \\${processName ?? "Unknown"} (PID: \\${pid ?? "-"})';
    } else if (scanType == 'file') {
      extraInfo = 'File: \\${fileName ?? "Unknown"}\nPath: \\${filePath ?? "-"}';
      if (threat['hash'] != null) {
        extraInfo += '\nSHA256: \\${threat['hash']}';
      }
    } else if (scanType == 'log') {
      extraInfo = 'Event ID: \\${eventId ?? "-"}\nSource: \\${sourceName ?? "-"}\nTime: \\${timeGenerated ?? "-"}';
    }

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: Icon(severityIcon, color: scoreColor, size: 32, semanticLabel: severity),
        title: Text(
          'Conclusion: ${conclusion[0].toUpperCase()}${conclusion.substring(1)}',
          style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Score: ${threatScore.toStringAsFixed(2)}',
              style: TextStyle(color: scoreColor, fontWeight: FontWeight.w600),
            ),
            Text(
              'Type: ${scanType}\nTime: ${formattedTime}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (extraInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(extraInfo, style: const TextStyle(color: Colors.white70)),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white70),
          tooltip: 'Show Details',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Scan Item Details', style: TextStyle(color: scoreColor)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Conclusion: ${conclusion[0].toUpperCase()}${conclusion.substring(1)}', style: TextStyle(color: scoreColor)),
                      Text('Threat Score: ${threatScore.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text('Type: ${scanType}'),
                      Text('Time: ${formattedTime}'),
                      if (scanType == 'process') ...[
                        const Divider(),
                        Text('Process Name: ${processName ?? "Unknown"}'),
                        Text('PID: ${pid ?? "-"}'),
                      ],
                      if (scanType == 'file') ...[
                        const Divider(),
                        Text('File Name: ${fileName ?? "Unknown"}'),
                        Text('File Path: ${filePath ?? "-"}'),
                        if (threat['hash'] != null)
                          Text('SHA256 Hash: \\${threat['hash']}'),
                      ],
                      if (scanType == 'log') ...[
                        const Divider(),
                        Text('Event ID: ${eventId ?? "-"}'),
                        Text('Source: ${sourceName ?? "-"}'),
                        Text('Time Generated: ${timeGenerated ?? "-"}'),
                        Text('Event Type: ${eventType ?? "-"}'),
                        Text('Event Category: ${eventCategory ?? "-"}'),
                        Text('Event Data: ${eventData ?? "-"}'),
                        Text('String Inserts: ${stringInserts ?? "-"}'),
                      ],
                      const Divider(),
                      const Text('Feature Vector:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...featureVector.map((v) => Text(v.toString())).toList(),
                      const Divider(),
                      const Text('Raw Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(threat.toString(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 