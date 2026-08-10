import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'recent_conversations_page.dart';
import '../../core/network/api_client.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;
  List<dynamic> contacts = [];
  List<dynamic> groups = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.dio.get('/contacts'),
        ApiClient.instance.dio.get('/groups'),
      ]);
      if (!mounted) return;
      setState(() {
        contacts = List<dynamic>.from(results[0].data);
        groups = List<dynamic>.from(results[1].data);
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openChat(dynamic user) async {
    final r = await ApiClient.instance.dio.post('/conversations/direct/${user['id']}');
    if (!mounted) return;
    context.push(
      '/chat/${r.data['id']}?name=${Uri.encodeQueryComponent(user['displayName'])}',
    );
  }

  Widget contactsPage() => RefreshIndicator(
        onRefresh: load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = contacts[i]['contact'];
            return Card(
              child: ListTile(
                onTap: () => openChat(u),
                leading: const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person_rounded),
                ),
                title: Text(
                  u['displayName'],
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${u['status']} • ${u['personalMsg'] ?? 'Disponível'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      );

  Widget groupsPage() => RefreshIndicator(
        onRefresh: load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
          itemCount: groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final g = groups[i];
            return Card(
              child: ListTile(
                onTap: () {
                  final name = Uri.encodeQueryComponent(g['title'] ?? 'Grupo');
                  context.push('/chat/${g['id']}?name=$name&group=1');
                },
                leading: const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.groups_rounded),
                ),
                title: Text(
                  g['title'] ?? 'Grupo',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('${(g['members'] as List?)?.length ?? 0} participantes'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      );

  List<Widget> get pages => [
        const RecentConversationsPage(),
        contactsPage(),
        groupsPage(),
        const _StatusShortcut(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 74,
        titleSpacing: 18,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LiveChat',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
            Text(
              'Messenger V8',
              style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Arquivadas',
            onPressed: () => context.push('/archived'),
            icon: const Icon(Icons.archive_outlined),
          ),
          IconButton(
            tooltip: 'Novo grupo',
            onPressed: () => context.push('/groups/create'),
            icon: const Icon(Icons.group_add_rounded),
          ),
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push('/profile'),
            icon: const CircleAvatar(child: Icon(Icons.person)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: loading && index != 0
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: KeyedSubtree(
                key: ValueKey(index),
                child: pages[index],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Conversas',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contatos',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Status',
          ),
        ],
      ),
      floatingActionButton: switch (index) {
        1 => FloatingActionButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Use a busca de usuários para adicionar contatos.')),
            ),
            child: const Icon(Icons.person_add_alt_1),
          ),
        2 => FloatingActionButton(
            onPressed: () => context.push('/groups/create'),
            child: const Icon(Icons.group_add),
          ),
        3 => FloatingActionButton(
            onPressed: () => context.push('/stories'),
            child: const Icon(Icons.add),
          ),
        _ => null,
      },
    );
  }
}

class _StatusShortcut extends StatelessWidget {
  const _StatusShortcut();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A78FF), Color(0xFF0D3B82)],
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 58),
              const SizedBox(height: 16),
              const Text(
                'Status LiveChat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Compartilhe texto, foto ou vídeo por 24 horas.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => context.push('/stories'),
                child: const Text('Abrir Status'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
