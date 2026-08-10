import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class PrivacyNotificationsPage extends StatefulWidget {
  const PrivacyNotificationsPage({super.key});

  @override
  State<PrivacyNotificationsPage> createState() =>
      _PrivacyNotificationsPageState();
}

class _PrivacyNotificationsPageState extends State<PrivacyNotificationsPage> {
  bool pushMessages = true;
  bool pushCalls = true;
  bool nudge = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/security/preferences');
    if (!mounted) return;

    setState(() {
      pushMessages = r.data['pushMessagesEnabled'] ?? true;
      pushCalls = r.data['pushCallsEnabled'] ?? true;
      nudge = r.data['nudgeEnabled'] ?? true;
      loading = false;
    });
  }

  Future<void> save() async {
    await ApiClient.instance.dio.post('/security/preferences', data: {
      'pushMessagesEnabled': pushMessages,
      'pushCallsEnabled': pushCalls,
      'nudgeEnabled': nudge,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e notificações')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                SwitchListTile(
                  value: pushMessages,
                  onChanged: (v) => setState(() => pushMessages = v),
                  title: const Text('Notificações de mensagens'),
                  subtitle: const Text('Receber mensagens com o app fechado'),
                ),
                SwitchListTile(
                  value: pushCalls,
                  onChanged: (v) => setState(() => pushCalls = v),
                  title: const Text('Notificações de chamadas'),
                  subtitle: const Text('Avisar quando alguém estiver ligando'),
                ),
                SwitchListTile(
                  value: nudge,
                  onChanged: (v) => setState(() => nudge = v),
                  title: const Text('Chamar Atenção'),
                  subtitle: const Text('Permitir o recurso nostálgico de chamar atenção'),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: save,
                  child: const Text('Salvar'),
                ),
              ],
            ),
    );
  }
}
