import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const LiveChatV13App());
}

class LiveChatV13App extends StatelessWidget {
  const LiveChatV13App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LiveChat Messenger V13',
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
      home: const ConnectionPage(),
    );
  }
}

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final name = TextEditingController();
  final server = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    name.text = prefs.getString('name') ?? '';
    server.text = prefs.getString('server') ?? '';
    if (mounted) setState(() => loading = false);
  }

  Future<void> connect() async {
    final n = name.text.trim();
    var s = server.text.trim();
    if (n.length < 2 || s.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome e o endereço do servidor.')),
      );
      return;
    }

    if (!s.startsWith('ws://') && !s.startsWith('wss://')) {
      s = 'wss://$s';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', n);
    await prefs.setString('server', s);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveChatHome(name: n, serverUrl: s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A78FF), Color(0xFF0D3B82)],
                      ),
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 72),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'LiveChat',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'Messenger V13 • Online',
                    style: TextStyle(color: Colors.lightBlueAccent),
                  ),
                  const SizedBox(height: 36),
                  if (loading)
                    const CircularProgressIndicator()
                  else ...[
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Seu apelido',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: server,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Servidor WebSocket',
                        hintText: 'wss://seu-servidor.com',
                        prefixIcon: Icon(Icons.cloud_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: connect,
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar no LiveChat'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A V13 usa um servidor WebSocket. O APK abre normalmente sem servidor, mas mensagens entre celulares só funcionam quando o backend estiver hospedado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LiveChatHome extends StatefulWidget {
  const LiveChatHome({super.key, required this.name, required this.serverUrl});

  final String name;
  final String serverUrl;

  @override
  State<LiveChatHome> createState() => _LiveChatHomeState();
}

class _LiveChatHomeState extends State<LiveChatHome> {
  WebSocketChannel? channel;
  StreamSubscription? subscription;
  bool connected = false;
  String? error;
  List<String> users = [];
  final Map<String, List<ChatMessage>> chats = {};
  int index = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final c = WebSocketChannel.connect(Uri.parse(widget.serverUrl));
      await c.ready.timeout(const Duration(seconds: 8));
      c.sink.add(jsonEncode({'type': 'hello', 'name': widget.name}));
      subscription = c.stream.listen(
        _handle,
        onError: (e) {
          if (mounted) setState(() {
            connected = false;
            error = 'Falha de conexão';
          });
        },
        onDone: () {
          if (mounted) setState(() => connected = false);
        },
      );
      if (mounted) setState(() {
        channel = c;
        connected = true;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() {
        connected = false;
        error = 'Servidor indisponível';
      });
    }
  }

  void _handle(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString()) as Map<String, dynamic>;
      switch (data['type']) {
        case 'presence':
          if (mounted) {
            setState(() {
              users = List<String>.from(data['users'] ?? [])
                ..remove(widget.name)
                ..sort();
            });
          }
          break;
        case 'message':
          final from = data['from']?.toString() ?? 'Contato';
          final text = data['text']?.toString() ?? '';
          if (text.isEmpty) return;
          if (mounted) {
            setState(() {
              chats.putIfAbsent(from, () => []);
              chats[from]!.add(ChatMessage(text: text, mine: false));
            });
          }
          break;
        case 'nudge':
          final from = data['from']?.toString() ?? 'Alguém';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('⭐ $from chamou sua atenção!')),
            );
          }
          break;
      }
    } catch (_) {}
  }

  void sendMessage(String to, String text) {
    if (!connected) return;
    channel?.sink.add(jsonEncode({
      'type': 'message',
      'to': to,
      'text': text,
    }));
    setState(() {
      chats.putIfAbsent(to, () => []);
      chats[to]!.add(ChatMessage(text: text, mine: true));
    });
  }

  void nudge(String to) {
    channel?.sink.add(jsonEncode({'type': 'nudge', 'to': to}));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('⭐ Você chamou a atenção de $to!')),
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnlineUsers(
        users: users,
        chats: chats,
        openChat: _openChat,
      ),
      _StatusView(name: widget.name, connected: connected, server: widget.serverUrl),
      _ProfileView(name: widget.name, connected: connected, reconnect: _connect),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LiveChat', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            Text(
              connected ? 'V13 • Online' : 'V13 • Desconectado',
              style: TextStyle(
                fontSize: 12,
                color: connected ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reconectar',
            onPressed: _connect,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!connected)
            MaterialBanner(
              content: Text(error ?? 'Servidor desconectado'),
              actions: [
                TextButton(onPressed: _connect, child: const Text('TENTAR NOVAMENTE')),
              ],
            ),
          Expanded(child: IndexedStack(index: index, children: pages)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Online',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  void _openChat(String name) {
    chats.putIfAbsent(name, () => []);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RealtimeChatPage(
          name: name,
          messages: chats[name]!,
          send: (text) => sendMessage(name, text),
          nudge: () => nudge(name),
        ),
      ),
    ).then((_) => setState(() {}));
  }
}

class _OnlineUsers extends StatelessWidget {
  const _OnlineUsers({required this.users, required this.chats, required this.openChat});

  final List<String> users;
  final Map<String, List<ChatMessage>> chats;
  final void Function(String) openChat;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const Text(
          'Pessoas online',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (users.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
              child: Text(
                'Nenhuma outra pessoa online agora.\nAbra o app em outro celular com outro apelido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
            ),
          )
        else
          ...users.map(
            (u) => Card(
              child: ListTile(
                onTap: () => openChat(u),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      child: Text(u.isNotEmpty ? u[0].toUpperCase() : '?'),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0D2748), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(u, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  chats[u]?.isNotEmpty == true ? chats[u]!.last.text : 'Online agora',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
      ],
    );
  }
}

class RealtimeChatPage extends StatefulWidget {
  const RealtimeChatPage({
    super.key,
    required this.name,
    required this.messages,
    required this.send,
    required this.nudge,
  });

  final String name;
  final List<ChatMessage> messages;
  final void Function(String) send;
  final VoidCallback nudge;

  @override
  State<RealtimeChatPage> createState() => _RealtimeChatPageState();
}

class _RealtimeChatPageState extends State<RealtimeChatPage> {
  final input = TextEditingController();

  void send() {
    final text = input.text.trim();
    if (text.isEmpty) return;
    widget.send(text);
    input.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text('● Online', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: widget.messages.length,
              itemBuilder: (_, i) {
                final m = widget.messages[i];
                return Align(
                  alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 295),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: m.mine ? const Color(0xFF0878FF) : const Color(0xFF173A67),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(m.text),
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
                  IconButton(
                    tooltip: 'Chamar Atenção',
                    onPressed: widget.nudge,
                    icon: const Icon(Icons.star_rounded, color: Colors.amber),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
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

class _StatusView extends StatelessWidget {
  const _StatusView({required this.name, required this.connected, required this.server});

  final String name;
  final bool connected;
  final String server;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF0A78FF), Color(0xFF0D3B82)],
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.auto_stories_rounded, size: 58),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              Text(connected ? 'Online no LiveChat' : 'Offline'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Servidor'),
            subtitle: Text(server),
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.name, required this.connected, required this.reconnect});

  final String name;
  final bool connected;
  final VoidCallback reconnect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 58,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 48)),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(name, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        ),
        Center(
          child: Text(
            connected ? '● Online' : '● Desconectado',
            style: TextStyle(color: connected ? Colors.greenAccent : Colors.redAccent),
          ),
        ),
        const SizedBox(height: 26),
        Card(
          child: ListTile(
            onTap: reconnect,
            leading: const Icon(Icons.refresh),
            title: const Text('Reconectar ao servidor'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('V13 Online'),
            subtitle: Text('Mensagens em tempo real + presença + Chamar Atenção'),
          ),
        ),
      ],
    );
  }
}

class ChatMessage {
  ChatMessage({required this.text, required this.mine});
  final String text;
  final bool mine;
}
