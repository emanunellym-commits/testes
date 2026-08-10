import 'package:flutter/material.dart';

void main() {
  runApp(const LiveChatDemoApp());
}

class LiveChatDemoApp extends StatelessWidget {
  const LiveChatDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LiveChat Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06152A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF178BFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          color: Color(0xFF0D2748),
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final contacts = const [
    ('Lucas', 'Online', 'Bora conversar?', Colors.green),
    ('Mariana', 'Ausente', 'No trabalho', Colors.orange),
    ('Rafael', 'Ocupado', 'Jogando', Colors.red),
    ('Camila', 'Online', 'Disponível', Colors.green),
    ('Pedro', 'Offline', 'Até mais tarde', Colors.grey),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LiveChat', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            Text('Messenger • Demo V12', style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Versão de demonstração'),
                content: Text('Este APK funciona sem servidor e serve para testar o visual e a navegação no celular.'),
              ),
            ),
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: [
          _Conversations(contacts: contacts),
          _Contacts(contacts: contacts),
          const _StatusPage(),
          const _ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Conversas'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Contatos'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _Conversations extends StatelessWidget {
  const _Conversations({required this.contacts});
  final List<(String, String, String, Color)> contacts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const TextField(
          decoration: InputDecoration(
            hintText: 'Buscar conversas...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        ...contacts.map((c) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatPage(name: c.$1)),
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: const Color(0xFF173A67),
                  child: Text(c.$1.substring(0, 1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: c.$4,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D2748), width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(c.$3, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('11:26', style: TextStyle(fontSize: 11)),
                SizedBox(height: 5),
                CircleAvatar(radius: 10, child: Text('2', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _Contacts extends StatelessWidget {
  const _Contacts({required this.contacts});
  final List<(String, String, String, Color)> contacts;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Contatos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ),
        ...contacts.map((c) => ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatPage(name: c.$1)),
          ),
          leading: CircleAvatar(child: Text(c.$1.substring(0, 1))),
          title: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${c.$2} • ${c.$3}'),
          trailing: Icon(Icons.circle, size: 12, color: c.$4),
        )),
      ],
    );
  }
}

class _StatusPage extends StatelessWidget {
  const _StatusPage();

  @override
  Widget build(BuildContext context) {
    final statuses = const [
      ('Lucas', 'Partiu rolê hoje 😎'),
      ('Mariana', 'Dia corrido por aqui!'),
      ('Camila', 'Saudades dos mensageiros antigos 💙'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(colors: [Color(0xFF0B78FF), Color(0xFF0D3C82)]),
          ),
          child: const Column(
            children: [
              Icon(Icons.auto_stories, size: 52),
              SizedBox(height: 10),
              Text('Seu Status', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
              Text('Compartilhe uma mensagem por 24 horas.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...statuses.map((s) => Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(s.$1.substring(0, 1))),
            title: Text(s.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(s.$2),
            trailing: const Icon(Icons.chevron_right),
          ),
        )),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(radius: 58, child: Icon(Icons.person, size: 62)),
        const SizedBox(height: 14),
        const Center(child: Text('Emanuel', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900))),
        const Center(child: Text('● Online', style: TextStyle(color: Colors.greenAccent))),
        const SizedBox(height: 28),
        Card(child: ListTile(leading: const Icon(Icons.palette_outlined), title: const Text('Temas'), subtitle: const Text('Clássico Azul'))),
        Card(child: ListTile(leading: const Icon(Icons.notifications_outlined), title: const Text('Notificações'))),
        Card(child: ListTile(leading: const Icon(Icons.security_outlined), title: const Text('Conta e segurança'))),
        Card(child: ListTile(leading: const Icon(Icons.support_agent), title: const Text('Suporte'))),
      ],
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.name});
  final String name;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <Map<String, dynamic>>[
    {'mine': false, 'text': 'Oi! Que legal esse LiveChat 😄'},
    {'mine': true, 'text': 'Ficou com uma pegada bem MSN, né?'},
    {'mine': false, 'text': 'Sim! E no celular ficou muito bom.'},
  ];

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add({'mine': true, 'text': text}));
    controller.clear();
  }

  void nudge() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⭐ Você chamou a atenção de ${widget.name}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text('Online', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          IconButton(onPressed: () => _demo(context, 'Chamada de voz'), icon: const Icon(Icons.call_outlined)),
          IconButton(onPressed: () => _demo(context, 'Videochamada'), icon: const Icon(Icons.videocam_outlined)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                return Align(
                  alignment: m['mine'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: m['mine'] ? const Color(0xFF0878FF) : const Color(0xFF173A67),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(m['text']),
                        if (m['mine']) const Text('✓✓ 11:26', style: TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Row(
                children: [
                  IconButton(onPressed: nudge, tooltip: 'Chamar Atenção', icon: const Icon(Icons.star_rounded, color: Colors.amber)),
                  IconButton(onPressed: () => _demo(context, 'Anexos'), icon: const Icon(Icons.add_circle_outline)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(hintText: 'Digite uma mensagem...'),
                    ),
                  ),
                  IconButton(onPressed: send, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _demo(BuildContext context, String feature) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(feature),
      content: const Text('Na versão demo esta função mostra apenas a interface. A função online entra quando conectarmos o servidor.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}
