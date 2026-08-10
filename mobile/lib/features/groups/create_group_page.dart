import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final title = TextEditingController();
  List<dynamic> contacts = [];
  final selected = <String>{};
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/contacts');
    if (mounted) {
      setState(() {
        contacts = List<dynamic>.from(r.data);
        loading = false;
      });
    }
  }

  Future<void> create() async {
    if (title.text.trim().length < 2) return;
    setState(() => saving = true);
    try {
      final r = await ApiClient.instance.dio.post('/groups', data: {
        'title': title.text.trim(),
        'memberIds': selected.toList(),
      });

      if (mounted) {
        final name = Uri.encodeQueryComponent(r.data['title'] ?? title.text.trim());
        context.go('/chat/${r.data['id']}?name=$name&group=1');
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo grupo')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Nome do grupo',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Participantes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...contacts.map((item) {
                  final u = item['contact'];
                  final id = u['id'] as String;
                  return CheckboxListTile(
                    value: selected.contains(id),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(id);
                        } else {
                          selected.remove(id);
                        }
                      });
                    },
                    title: Text(u['displayName']),
                    subtitle: Text('@${u['username']}'),
                    secondary: const CircleAvatar(child: Icon(Icons.person)),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saving ? null : create,
                    icon: const Icon(Icons.add),
                    label: Text(saving ? 'Criando...' : 'Criar grupo'),
                  ),
                ),
              ],
            ),
    );
  }
}
