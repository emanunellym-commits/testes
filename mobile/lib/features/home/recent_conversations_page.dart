import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class RecentConversationsPage extends StatefulWidget {
  const RecentConversationsPage({super.key});

  @override
  State<RecentConversationsPage> createState() => _RecentConversationsPageState();
}

class _RecentConversationsPageState extends State<RecentConversationsPage> {
  List<dynamic> items = [];
  List<dynamic> filtered = [];
  bool loading = true;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/conversations');
    if (!mounted) return;
    setState(() {
      items = List<dynamic>.from(r.data);
      filtered = items;
      loading = false;
    });
  }

  String titleFor(dynamic c) {
    if (c['type'] == 'GROUP') return c['title'] ?? 'Grupo';
    final members = List<dynamic>.from(c['members'] ?? []);
    if (members.isEmpty) return 'Conversa';
    return members.last['user']['displayName'] ?? 'Contato';
  }

  void filter(String q) {
    final needle = q.trim().toLowerCase();
    setState(() {
      filtered = needle.isEmpty
          ? items
          : items.where((c) {
              final title = titleFor(c).toLowerCase();
              final last = (c['messages'] as List?)?.isNotEmpty == true
                  ? (c['messages'][0]['body'] ?? '').toString().toLowerCase()
                  : '';
              return title.contains(needle) || last.contains(needle);
            }).toList();
    });
  }

  Future<void> pin(dynamic c) async {
    await ApiClient.instance.dio.post(
      '/conversations/${c['id']}/pin',
      data: {'pinned': c['pinnedAt'] == null},
    );
    await load();
  }

  Future<void> archive(dynamic c) async {
    await ApiClient.instance.dio.post(
      '/conversations/${c['id']}/archive',
      data: {'archived': true},
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
        children: [
          TextField(
            controller: search,
            onChanged: filter,
            decoration: const InputDecoration(
              hintText: 'Buscar conversas...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: Text('Nenhuma conversa encontrada.')),
            )
          else
            ...filtered.map((c) {
              final last = (c['messages'] as List?)?.isNotEmpty == true
                  ? c['messages'][0]
                  : null;
              final unread = c['unreadCount'] ?? 0;

              return Dismissible(
                key: ValueKey(c['id']),
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.blueGrey,
                  ),
                  child: const Icon(Icons.archive_outlined),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.indigo,
                  ),
                  child: const Icon(Icons.push_pin_outlined),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await archive(c);
                  } else {
                    await pin(c);
                  }
                  return false;
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    onTap: () {
                      final name = Uri.encodeQueryComponent(titleFor(c));
                      context.push(
                        '/chat/${c['id']}?name=$name&group=${c['type'] == 'GROUP' ? 1 : 0}',
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Icon(
                            c['type'] == 'GROUP'
                                ? Icons.groups_rounded
                                : Icons.person,
                          ),
                        ),
                        if (c['pinnedAt'] != null)
                          const Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 9,
                              child: Icon(Icons.push_pin, size: 11),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      titleFor(c),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      last?['body']?.toString().isNotEmpty == true
                          ? last['body']
                          : 'Sem mensagens ainda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 13,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(fontSize: 10),
                            ),
                          )
                        : const Icon(Icons.chevron_right),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
