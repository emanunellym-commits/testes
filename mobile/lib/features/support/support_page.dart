import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  List<dynamic> tickets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/support/mine');
    if (!mounted) return;
    setState(() {
      tickets = List<dynamic>.from(r.data);
      loading = false;
    });
  }

  Future<void> createTicket() async {
    final subject = TextEditingController();
    final message = TextEditingController();
    String priority = 'NORMAL';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setLocal) => AlertDialog(
          title: const Text('Novo atendimento'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(labelText: 'Assunto'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Baixa')),
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                    DropdownMenuItem(value: 'HIGH', child: Text('Alta')),
                    DropdownMenuItem(value: 'URGENT', child: Text('Urgente')),
                  ],
                  onChanged: (v) => setLocal(() => priority = v ?? priority),
                  decoration: const InputDecoration(labelText: 'Prioridade'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: message,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Mensagem'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                await ApiClient.instance.dio.post('/support', data: {
                  'subject': subject.text.trim(),
                  'message': message.text.trim(),
                  'priority': priority,
                });
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                await load();
              },
              child: const Text('Abrir ticket'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte'),
        actions: [
          IconButton(
            onPressed: createTicket,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? Center(
                  child: FilledButton.icon(
                    onPressed: createTicket,
                    icon: const Icon(Icons.support_agent),
                    label: const Text('Abrir atendimento'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final t = tickets[i];
                    return Card(
                      child: ExpansionTile(
                        title: Text(t['subject']),
                        subtitle: Text('${t['status']} • ${t['priority']}'),
                        children: [
                          ...(t['messages'] as List<dynamic>).map(
                            (m) => ListTile(
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: Text(m['body']),
                              subtitle: Text(m['createdAt'] ?? ''),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: createTicket,
        child: const Icon(Icons.add),
      ),
    );
  }
}
