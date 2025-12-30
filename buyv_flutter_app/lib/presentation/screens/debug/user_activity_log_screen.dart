import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/remote_logger.dart';

/// 📋 Écran d'historique des actions utilisateur
/// Format: "L'utilisateur s'est connecté à 14:30", "A cliqué sur Profile à 14:31"
class UserActivityLogScreen extends StatefulWidget {
  const UserActivityLogScreen({super.key});

  @override
  State<UserActivityLogScreen> createState() => _UserActivityLogScreenState();
}

class _UserActivityLogScreenState extends State<UserActivityLogScreen> {
  List<LogEntry> _logs = [];
  String _filter = 'all'; // all, user, system

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = RemoteLogger.getLogs();
    });
  }

  List<LogEntry> get _filteredLogs {
    if (_filter == 'user') {
      return _logs.where((log) => log.message.contains('👤 CLIENT')).toList();
    } else if (_filter == 'system') {
      return _logs.where((log) => !log.message.contains('👤 CLIENT')).toList();
    }
    return _logs;
  }

  String _formatLogToUserAction(LogEntry log) {
    final time = _formatTime(log.timestamp);
    
    // Si c'est une action utilisateur
    if (log.message.contains('👤 CLIENT:')) {
      final action = log.message.replaceFirst('👤 CLIENT: ', '');
      return _translateAction(action, time, log.data);
    }
    
    // Si c'est un événement Flutter
    if (log.message.contains('📱 FLUTTER:')) {
      final event = log.message.replaceFirst('📱 FLUTTER: ', '');
      return '  → $event à $time';
    }
    
    // Si c'est un appel backend
    if (log.message.contains('🔧 BACKEND:')) {
      final call = log.message.replaceFirst('🔧 BACKEND: ', '');
      return '    ↳ API: $call à $time';
    }
    
    // Si c'est une réponse backend
    if (log.message.contains('✅ BACKEND RESPONSE:')) {
      final response = log.message.replaceFirst('✅ BACKEND RESPONSE: ', '');
      final status = log.data?['statusCode'] ?? '?';
      return '    ✓ $response (Status: $status) à $time';
    }
    
    return '$time: ${log.message}';
  }

  String _translateAction(String action, String time, Map<String, dynamic>? data) {
    // Traductions des actions en français naturel
    if (action.contains('Load profile data')) {
      final userId = data?['userId'] ?? 'inconnu';
      return '🔵 L\'utilisateur a ouvert son profil à $time';
    }
    
    if (action.contains('Tap video from profile')) {
      final tab = data?['tab'];
      final section = tab == 0 ? 'Reels' : tab == 2 ? 'Enregistrés' : 'Produits';
      return '🎬 A cliqué sur une vidéo ($section) à $time';
    }
    
    if (action.contains('Switch to tab')) {
      final tabName = data?['tabName'] ?? 'Tab';
      return '📑 A basculé vers l\'onglet $tabName à $time';
    }
    
    if (action.contains('Bookmark')) {
      return '⭐ A enregistré un post à $time';
    }
    
    if (action.contains('Unbookmark')) {
      return '🗑️ A retiré un post des enregistrements à $time';
    }
    
    if (action.contains('Like')) {
      return '❤️ A aimé un post à $time';
    }
    
    if (action.contains('Unlike')) {
      return '💔 A retiré un like à $time';
    }
    
    if (action.contains('Refresh')) {
      return '🔄 A rafraîchi la page à $time';
    }
    
    if (action.contains('Login') || action.contains('Sign in')) {
      return '🔐 S\'est connecté à $time';
    }
    
    if (action.contains('Logout')) {
      return '🚪 S\'est déconnecté à $time';
    }
    
    // Action générique
    return '📌 $action à $time';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique d\'Activité'),
        backgroundColor: const Color(0xFF0D3D67),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              RemoteLogger.clear();
              _loadLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Historique effacé')),
              );
            },
            tooltip: 'Effacer',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: RemoteLogger.getLogsAsText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs copiés dans le presse-papier')),
              );
            },
            tooltip: 'Copier',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Filtrer: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Tout'),
                  selected: _filter == 'all',
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = 'all');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('👤 Utilisateur'),
                  selected: _filter == 'user',
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = 'user');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('⚙️ Système'),
                  selected: _filter == 'system',
                  onSelected: (selected) {
                    if (selected) setState(() => _filter = 'system');
                  },
                ),
              ],
            ),
          ),
          
          // Stats
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0D3D67).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', _logs.length),
                _buildStat('Actions', _logs.where((l) => l.message.contains('👤 CLIENT')).length),
                _buildStat('API', _logs.where((l) => l.message.contains('🔧 BACKEND')).length),
              ],
            ),
          ),
          
          // Liste des logs
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune activité enregistrée',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[_filteredLogs.length - 1 - index]; // Inverse (plus récent en haut)
                      return _buildLogCard(log);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D3D67),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLogCard(LogEntry log) {
    final formattedLog = _formatLogToUserAction(log);
    final isUserAction = log.message.contains('👤 CLIENT');
    final isError = log.level == LogLevel.error;
    
    Color bgColor = Colors.white;
    if (isUserAction) bgColor = Colors.blue[50]!;
    if (isError) bgColor = Colors.red[50]!;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bgColor,
      elevation: isUserAction ? 2 : 0,
      child: ListTile(
        dense: true,
        title: Text(
          formattedLog,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isUserAction ? FontWeight.w600 : FontWeight.normal,
            color: isError ? Colors.red[900] : Colors.black87,
          ),
        ),
        subtitle: log.data?['actionId'] != null
            ? Text(
                'ID: ${log.data!['actionId']}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              )
            : null,
        trailing: isUserAction
            ? const Icon(Icons.person, size: 16, color: Colors.blue)
            : null,
      ),
    );
  }
}
