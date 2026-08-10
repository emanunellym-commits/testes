import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  List<dynamic> sessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/sessions');
    if (!mounted) return;
    setState(() {
      sessions = List<dynamic>.from(r.data);
      loading = false;
    });
  }

  Future<void> revoke(String id) async {
    await ApiClient.instance.dio.delete('/sessions/$id');
    await load();
  }

  Future<void> revokeAll() async {
    await ApiClient.instance.dio.post('/sessions/revoke-all');
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos e sessões'),
        actions: [
          IconButton(
            tooltip: 'Encerrar todas',
            onPressed: revokeAll,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : sessions.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma sessão persistente registrada ainda.\n'
                    'As sessões aparecerão após o fluxo de refresh token ser ativado.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = sessions[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.devices),
                        ),
                        title: Text(s['deviceName'] ?? 'Dispositivo'),
                        subtitle: Text(
                          '${s['platform'] ?? 'plataforma desconhecida'}\n'
                          'Último uso: ${s['lastUsedAt'] ?? '-'}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          onPressed: () => revoke(s['id']),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
