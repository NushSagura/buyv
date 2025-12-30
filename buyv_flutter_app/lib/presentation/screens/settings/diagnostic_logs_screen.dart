import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/remote_logger.dart';

class DiagnosticLogsScreen extends StatefulWidget {
  const DiagnosticLogsScreen({super.key});

  @override
  State<DiagnosticLogsScreen> createState() => _DiagnosticLogsScreenState();
}

class _DiagnosticLogsScreenState extends State<DiagnosticLogsScreen> {
  @override
  Widget build(BuildContext context) {
    final logs = RemoteLogger.getLogs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs',
            onPressed: () => _copyLogs(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share logs',
            onPressed: _shareLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () => _confirmClearLogs(context),
          ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No logs yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Logs will appear here when using the app',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  leading: _getIconForLevel(log.level),
                  title: Text(
                    log.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(log.timestamp),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (log.data != null && log.data!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          log.data.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: logs.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                setState(() {}); // Refresh
              },
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return const Icon(Icons.bug_report, size: 20, color: Colors.blue);
      case LogLevel.info:
        return const Icon(Icons.info, size: 20, color: Colors.green);
      case LogLevel.warning:
        return const Icon(Icons.warning, size: 20, color: Colors.orange);
      case LogLevel.error:
        return const Icon(Icons.error, size: 20, color: Colors.red);
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Future<void> _copyLogs(BuildContext context) async {
    final text = RemoteLogger.getLogsAsText();
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logs copied to clipboard')),
      );
    }
  }

  Future<void> _shareLogs() async {
    final text = RemoteLogger.getLogsAsText();
    await Share.share(
      text,
      subject: 'BuyV App Diagnostic Logs',
    );
  }

  Future<void> _confirmClearLogs(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs?'),
        content: const Text('This will delete all diagnostic logs.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      RemoteLogger.clear();
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logs cleared')),
        );
      }
    }
  }
}
