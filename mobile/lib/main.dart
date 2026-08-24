import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(const LiveChatV14App());

const bg = Color(0xFF04162F);
const panel = Color(0xFF0A274A);
const panel2 = Color(0xFF10365F);
const blue = Color(0xFF0D82FF);
const cyan = Color(0xFF30D5FF);
const green = Color(0xFF22E65D);

class LiveChatV14App extends StatelessWidget {
  const LiveChatV14App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LiveChat Messenger V14 Premium',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: ColorScheme.fromSeed(seedColor: blue, brightness: Brightness.dark),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF102F55),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFF195080))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: cyan)),
          ),
        ),
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final name = TextEditingController();
  final server = TextEditingController(text: 'ws://37.148.135.182:8080');
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    name.text = p.getString('name') ?? '';
    server.text = p.getString('server') ?? 'ws://37.148.135.182:8080';
    if (mounted) setState(() => loading = false);
  }

  Future<void> enter() async {
    final n = name.text.trim();
    var s = server.text.trim();
    if (n.length < 2 || s.isEmpty) return;
    if (!s.startsWith('ws://') && !s.startsWith('wss://')) s = 'ws://$s';
    final p = await SharedPreferences.getInstance();
    await p.setString('name', n);
    await p.setString('server', s);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage(name: n, serverUrl: s)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF61C4FF), Color(0xFF0B5FAE), Color(0xFF04162F)]),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(26),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const BuddyLogo(size: 155),
                      const SizedBox(height: 12),
                      const Text('LiveChat', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: -2)),
                      const Text('Messenger', style: TextStyle(fontSize: 23)),
                      const SizedBox(height: 12),
                      const Text('Conectando você com o mundo,\ncomo nos velhos e bons tempos!', textAlign: TextAlign.center),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xD9082342),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: const Color(0x664ED9FF)),
                          boxShadow: const [BoxShadow(color: Color(0x5500B7FF), blurRadius: 24)],
                        ),
                        child: loading
                            ? const Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Seu apelido', prefixIcon: Icon(Icons.person))),
                                  const SizedBox(height: 12),
                                  TextField(controller: server, decoration: const InputDecoration(labelText: 'Servidor', prefixIcon: Icon(Icons.cloud))),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF08C77B)),
                                      onPressed: enter,
                                      child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(onPressed: () {}, child: const Text('Criar conta')),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.name, required this.serverUrl});
  final String name;
  final String serverUrl;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  WebSocketChannel? channel;
  StreamSubscription? sub;
  bool connected = false;
  String? error;
  List<String> users = [];
  final Map<String, List<MessageItem>> chats = {};
  int index = 0;

  @override
  void initState() {
    super.initState();
    connect();
  }

  Future<void> connect() async {
    try {
      final c = WebSocketChannel.connect(Uri.parse(widget.serverUrl));
      await c.ready.timeout(const Duration(seconds: 8));
      c.sink.add(jsonEncode({'type': 'hello', 'name': widget.name}));
      await sub?.cancel();
      sub = c.stream.listen(handle, onError: (_) => mounted ? setState(() => connected = false) : null, onDone: () => mounted ? setState(() => connected = false) : null);
      if (mounted) setState(() { channel = c; connected = true; error = null; });
    } catch (_) {
      if (mounted) setState(() { connected = false; error = 'Servidor indisponível'; });
    }
  }

  void handle(dynamic raw) {
    try {
      final d = jsonDecode(raw.toString()) as Map<String, dynamic>;
      if (d['type'] == 'presence') {
        setState(() { users = List<String>.from(d['users'] ?? [])..remove(widget.name)..sort(); });
      } else if (d['type'] == 'message') {
        final from = d['from']?.toString() ?? 'Contato';
        final text = d['text']?.toString() ?? '';
        if (text.isEmpty) return;
        setState(() { chats.putIfAbsent(from, () => []); chats[from]!.add(MessageItem(text, false)); });
      } else if (d['type'] == 'nudge') {
        final from = d['from']?.toString() ?? 'Alguém';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⭐ $from chamou sua atenção!')));
      }
    } catch (_) {}
  }

  void send(String to, String text) {
    if (!connected || text.trim().isEmpty) return;
    channel?.sink.add(jsonEncode({'type': 'message', 'to': to, 'text': text.trim()}));
    setState(() { chats.putIfAbsent(to, () => []); chats[to]!.add(MessageItem(text.trim(), true)); });
  }

  void nudge(String to) {
    channel?.sink.add(jsonEncode({'type': 'nudge', 'to': to}));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⭐ Você chamou a atenção de $to!')));
  }

  void openChat(String user) {
    chats.putIfAbsent(user, () => []);
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(name: user, messages: chats[user]!, onSend: (t) => send(user, t), onNudge: () => nudge(user)))).then((_) => setState(() {}));
  }

  @override
  void dispose() {
    sub?.cancel();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ContactsPage(me: widget.name, users: users, chats: chats, connected: connected, onOpen: openChat),
      ConversationsPage(chats: chats, onOpen: openChat),
      const GroupsPage(),
      StatusPage(connected: connected),
      ProfilePage(name: widget.name, connected: connected, server: widget.serverUrl),
    ];
    return Scaffold(
      body: Column(children: [
        if (!connected) MaterialBanner(content: Text(error ?? 'Desconectado'), actions: [TextButton(onPressed: connect, child: const Text('RECONECTAR'))]),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF06182F),
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Contatos'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Conversas'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Grupos'),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.me, required this.users, required this.chats, required this.connected, required this.onOpen});
  final String me;
  final List<String> users;
  final Map<String, List<MessageItem>> chats;
  final bool connected;
  final void Function(String) onOpen;
  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = widget.users.where((u) => u.toLowerCase().contains(q.toLowerCase())).toList();
    return SafeArea(
      bottom: false,
      child: Column(children: [
        PremiumHeader(title: 'LiveChat', subtitle: widget.connected ? 'Online' : 'Desconectado', color: widget.connected ? green : Colors.redAccent),
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 6), child: MeCard(name: widget.me, connected: widget.connected)),
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 10), child: TextField(onChanged: (v) => setState(() => q = v), decoration: const InputDecoration(hintText: 'Buscar contatos...', prefixIcon: Icon(Icons.search)))),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Nenhum contato online.\nAbra o LiveChat em outro celular\ncom outro apelido.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)))
              : ListView(padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                  const SectionTitle('Favoritos'),
                  ...list.take(4).map((u) => ContactTile(user: u, favorite: true, last: widget.chats[u]?.isNotEmpty == true ? widget.chats[u]!.last.text : 'Online', onTap: () => widget.onOpen(u))),
                  const SectionTitle('Contatos'),
                  ...list.map((u) => ContactTile(user: u, favorite: false, last: widget.chats[u]?.isNotEmpty == true ? widget.chats[u]!.last.text : 'Online', onTap: () => widget.onOpen(u))),
                ]),
        ),
      ]),
    );
  }
}

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key, required this.chats, required this.onOpen});
  final Map<String, List<MessageItem>> chats;
  final void Function(String) onOpen;
  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Column(children: [
          const PremiumHeader(title: 'Conversas', subtitle: 'Mensagens em tempo real', color: cyan),
          Expanded(
            child: chats.isEmpty
                ? const Center(child: Text('Suas conversas aparecerão aqui.', style: TextStyle(color: Colors.white60)))
                : ListView(padding: const EdgeInsets.all(14), children: chats.entries.map((e) => Card(color: panel, child: ListTile(onTap: () => onOpen(e.key), leading: Avatar(name: e.key), title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(e.value.isEmpty ? 'Sem mensagens' : e.value.last.text, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right)))).toList()),
          ),
        ]),
      );
}

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final groups = [('🚗','Carros Rebaixados','128 membros','Encontro amanhã 🔥'),('🎮','GTA RP Brasil','256 membros','Alguém on na cidade?'),('🎬','Séries e Filmes','89 membros','Alguém viu a nova temp?'),('⚽','Futebol Resenha','214 membros','Que gol foi esse! 😅'),('🎵','Músicas','76 membros','Playlist top pra hoje 🎧'),('👥','Amigos Online','52 membros','Bora jogarrr! 🎮')];
    return SafeArea(bottom: false, child: Column(children: [
      const PremiumHeader(title: 'Grupos', subtitle: 'Meus grupos', color: cyan),
      Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 4), child: TextField(decoration: const InputDecoration(hintText: 'Buscar grupos...', prefixIcon: Icon(Icons.search)))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(14), itemCount: groups.length, itemBuilder: (_, i) { final g = groups[i]; return Container(margin: const EdgeInsets.only(bottom: 9), decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(20)), child: ListTile(leading: CircleAvatar(backgroundColor: const Color(0xFF143F70), child: Text(g.$1)), title: Text(g.$2, style: const TextStyle(color: Color(0xFF10213D), fontWeight: FontWeight.w900)), subtitle: Text('${g.$3}\n${g.$4}', style: const TextStyle(color: Color(0xFF294B73))), isThreeLine: true, trailing: i < 2 ? CircleAvatar(radius: 15, backgroundColor: blue, child: Text(i == 0 ? '99+' : '32', style: const TextStyle(fontSize: 9))) : const Icon(Icons.chevron_right, color: Color(0xFF143F70)))); })),
    ]));
  }
}

class StatusPage extends StatelessWidget {
  const StatusPage({super.key, required this.connected});
  final bool connected;
  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: Column(children: [
    const PremiumHeader(title: 'Status', subtitle: 'Escolha como aparecer', color: green),
    Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [
      StatusTile(color: connected ? green : Colors.redAccent, title: connected ? 'Online' : 'Desconectado', subtitle: 'Vivendo um dia de cada vez...♪'),
      const StatusTile(color: Colors.amber, title: 'Ausente', subtitle: 'Volto já...'),
      const StatusTile(color: Colors.redAccent, title: 'Ocupado', subtitle: 'Não perturbe'),
      const StatusTile(color: Colors.blueGrey, title: 'Invisível', subtitle: 'Aparecer offline'),
    ])),
  ]));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.name, required this.connected, required this.server});
  final String name;
  final bool connected;
  final String server;
  @override
  Widget build(BuildContext context) => SafeArea(bottom: false, child: Column(children: [
    const PremiumHeader(title: 'Meu Perfil', subtitle: 'Personalize seu LiveChat', color: cyan),
    Expanded(child: ListView(padding: const EdgeInsets.all(18), children: [
      Center(child: Avatar(name: name, radius: 56)),
      const SizedBox(height: 12),
      Center(child: Text('$name 👑', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900))),
      Center(child: Text(connected ? '● Online' : '● Offline', style: TextStyle(color: connected ? green : Colors.redAccent))),
      const SizedBox(height: 20),
      ProfileTile(icon: Icons.music_note, title: 'Mensagem pessoal', subtitle: 'Vivendo um dia de cada vez...♪'),
      ProfileTile(icon: Icons.person_outline, title: 'Usuário', subtitle: name.toLowerCase()),
      ProfileTile(icon: Icons.cloud_outlined, title: 'Servidor', subtitle: server),
      const SizedBox(height: 14),
      const Text('Tema', style: TextStyle(fontWeight: FontWeight.w900)),
      const ThemeTile(name: 'MSN Azul', color: blue, selected: true),
      const ThemeTile(name: 'MSN Escuro', color: Colors.black),
      const ThemeTile(name: 'MSN Clássico', color: Color(0xFF9AB9ED)),
      const FeatureCard(emoji: '😊', title: 'Emoticons Clássicos', subtitle: '😀 😂 😍 😎 ❤️ 🤖 🐮'),
      const FeatureCard(emoji: '⭐', title: 'Chamar Atenção', subtitle: 'Disponível dentro das conversas.'),
    ])),
  ]));
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.name, required this.messages, required this.onSend, required this.onNudge});
  final String name;
  final List<MessageItem> messages;
  final void Function(String) onSend;
  final VoidCallback onNudge;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  void send() { final t = input.text.trim(); if (t.isEmpty) return; widget.onSend(t); input.clear(); setState(() {}); }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF08264B),
          titleSpacing: 0,
          title: Row(children: [Avatar(name: widget.name, radius: 21), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), const Text('● Online', style: TextStyle(fontSize: 11, color: green))])]),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: cyan)), IconButton(onPressed: () {}, icon: const Icon(Icons.videocam, color: cyan)), IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
        ),
        body: Column(children: [
          Expanded(child: widget.messages.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Avatar(name: widget.name, radius: 42), const SizedBox(height: 12), Text('Comece uma conversa com ${widget.name}', style: const TextStyle(color: Colors.white70))])) : ListView.builder(padding: const EdgeInsets.all(14), itemCount: widget.messages.length, itemBuilder: (_, i) { final m = widget.messages[i]; return Align(alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(constraints: const BoxConstraints(maxWidth: 300), margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11), decoration: BoxDecoration(gradient: m.mine ? const LinearGradient(colors: [Color(0xFF0062E8), blue]) : const LinearGradient(colors: [Color(0xFF38527A), Color(0xFF223D66)]), borderRadius: BorderRadius.circular(18)), child: Text(m.text))); })),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 5),
            decoration: const BoxDecoration(color: Color(0xFF071A33), border: Border(top: BorderSide(color: Color(0xFF174574)))),
            child: SafeArea(top: false, child: Column(children: [
              Row(children: [IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline, color: cyan)), Expanded(child: TextField(controller: input, onSubmitted: (_) => send(), decoration: const InputDecoration(hintText: 'Digite uma mensagem...', suffixIcon: Icon(Icons.emoji_emotions_outlined)))), const SizedBox(width: 6), CircleAvatar(backgroundColor: blue, child: IconButton(onPressed: send, icon: const Icon(Icons.send, color: Colors.white)))]),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ChatTool(Icons.emoji_emotions_outlined, 'Emojis', () {}), ChatTool(Icons.image_outlined, 'Fotos', () {}), ChatTool(Icons.photo_camera_outlined, 'Câmera', () {}), ChatTool(Icons.mic_none, 'Áudio', () {}), ChatTool(Icons.insert_drive_file_outlined, 'Arquivos', () {}), ChatTool(Icons.star_rounded, 'ATENÇÃO!', widget.onNudge, color: Colors.amber)]),
            ])),
          ),
        ]),
      );
}

class PremiumHeader extends StatelessWidget {
  const PremiumHeader({super.key, required this.title, required this.subtitle, required this.color});
  final String title, subtitle;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0B3970), Color(0xFF071E3B)]), border: Border(bottom: BorderSide(color: Color(0xFF18518A)))),
        child: Row(children: [const BuddyLogo(size: 42), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)), Row(children: [CircleAvatar(radius: 4, backgroundColor: color), const SizedBox(width: 6), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70))])])), IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1_outlined))]),
      );
}

class MeCard extends StatelessWidget {
  const MeCard({super.key, required this.name, required this.connected});
  final String name;
  final bool connected;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0F315C), Color(0xFF092340)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF155288))),
        child: Row(children: [Avatar(name: name, radius: 32), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$name 👑', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), const Text('Vivendo um dia de cada vez...♪', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white70, fontSize: 12)), Text(connected ? '● Online' : '● Offline', style: TextStyle(color: connected ? green : Colors.redAccent, fontSize: 11))])), const CircleAvatar(backgroundColor: blue, radius: 14, child: Icon(Icons.sync, size: 15))]),
      );
}

class ContactTile extends StatelessWidget {
  const ContactTile({super.key, required this.user, required this.favorite, required this.last, required this.onTap});
  final String user, last;
  final bool favorite;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF12436F))),
        child: ListTile(onTap: onTap, leading: Avatar(name: user), title: Text(user, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('● Online', style: TextStyle(color: green, fontSize: 12)), Text(last, maxLines: 1, overflow: TextOverflow.ellipsis)]), trailing: favorite ? const Icon(Icons.star, color: Colors.amber) : const Icon(Icons.chevron_right)),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(6, 8, 6, 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white70)));
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.radius = 27});
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Container(width: radius * 2, height: radius * 2, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFF113E72), Color(0xFF0A6FD0)]), border: Border.all(color: cyan, width: 1.4), boxShadow: const [BoxShadow(color: Color(0x5500B7FF), blurRadius: 8)]), alignment: Alignment.center, child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: TextStyle(fontSize: radius * .85, fontWeight: FontWeight.w900))),
        Positioned(right: -1, bottom: 1, child: Container(width: radius * .48, height: radius * .48, decoration: BoxDecoration(shape: BoxShape.circle, color: green, border: Border.all(color: panel, width: 2))))
      ]);
}

class BuddyLogo extends StatelessWidget {
  const BuddyLogo({super.key, required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size * .8, child: Stack(alignment: Alignment.center, children: [
        Positioned(left: size * .08, bottom: 0, child: Container(width: size * .48, height: size * .48, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFF8DFF9F), Color(0xFF18C84C), Color(0xFF07832F)])))),
        Positioned(right: size * .08, top: size * .02, child: Container(width: size * .52, height: size * .52, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFAEEFFF), Color(0xFF2CB7FF), Color(0xFF0068C9)])))),
        Positioned(bottom: size * .05, child: Transform.rotate(angle: -.08, child: Container(width: size * .9, height: size * .13, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), border: Border.all(color: const Color(0xFFFFB313), width: 4)))))
      ]));
}

class StatusTile extends StatelessWidget {
  const StatusTile({super.key, required this.color, required this.title, required this.subtitle});
  final Color color;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(color: panel, child: ListTile(leading: CircleAvatar(radius: 8, backgroundColor: color), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)));
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(color: panel, child: ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)));
}

class ThemeTile extends StatelessWidget {
  const ThemeTile({super.key, required this.name, required this.color, this.selected = false});
  final String name;
  final Color color;
  final bool selected;
  @override
  Widget build(BuildContext context) => Card(color: panel, child: ListTile(leading: CircleAvatar(radius: 10, backgroundColor: color), title: Text(name), trailing: selected ? const Icon(Icons.check_circle, color: blue) : const Icon(Icons.chevron_right)));
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.emoji, required this.title, required this.subtitle});
  final String emoji, title, subtitle;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF16476F))), child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 32)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: Colors.white60))]))]));
}

class ChatTool extends StatelessWidget {
  const ChatTool(this.icon, this.label, this.onTap, {super.key, this.color});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5), child: Column(children: [Icon(icon, size: 22, color: color ?? Colors.white70), Text(label, style: TextStyle(fontSize: 8, color: color ?? Colors.white70))])));
}

class MessageItem {
  MessageItem(this.text, this.mine);
  final String text;
  final bool mine;
}
