import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class ArchivedConversationsPage extends StatefulWidget {
  const ArchivedConversationsPage({super.key});

  @override
  State<ArchivedConversationsPage> createState() =>
      _ArchivedConversationsPageState();
}

class _ArchivedConversationsPageState
    extends State<ArchivedConversationsPage> {
  List<dynamic> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get(
      '/conversations',
      queryParameters: {'archived': '1'},
    );
    if (!mounted) return;
    setState(() {
      items = List<dynamic>.from(r.data);
      loading = false;
    });
  }

  String titleFor(dynamic c) {
    if (c['type'] == 'GROUP') return c['title'] ?? 'Grupo';
    final members = List<dynamic>.from(c['members'] ?? []);
    return members.isNotEmpty
        ? (members.last['user']['displayName'] ?? 'Contato')
        : 'Conversa';
  }

  Future<void> unarchive(dynamic c) async {
    await ApiClient.instance.dio.post(
      '/conversations/${c['id']}/archive',
      data: {'archived': false},
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversas arquivadas')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Nenhuma conversa arquivada.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          final name = Uri.encodeQueryComponent(titleFor(c));
                          context.push(
                            '/chat/${c['id']}?name=$name&group=${c['type'] == 'GROUP' ? 1 : 0}',
                          );
                        },
                        leading: CircleAvatar(
                          child: Icon(
                            c['type'] == 'GROUP'
                                ? Icons.groups_rounded
                                : Icons.person,
                          ),
                        ),
                        title: Text(titleFor(c)),
                        trailing: IconButton(
                          tooltip: 'Desarquivar',
                          onPressed: () => unarchive(c),
                          icon: const Icon(Icons.unarchive_outlined),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
