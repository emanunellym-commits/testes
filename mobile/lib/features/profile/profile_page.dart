import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? me;
  bool loading = true;
  bool uploading = false;
  final picker = ImagePicker();
  final displayName = TextEditingController();
  final personalMsg = TextEditingController();
  String status = 'ONLINE';

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/auth/me');
    me = Map<String, dynamic>.from(r.data);
    displayName.text = me?['displayName'] ?? '';
    personalMsg.text = me?['personalMsg'] ?? '';
    status = me?['status'] ?? 'ONLINE';
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    final r = await ApiClient.instance.dio.patch('/users/me', data: {
      'displayName': displayName.text.trim(),
      'personalMsg': personalMsg.text.trim(),
    });
    me = {...?me, ...Map<String, dynamic>.from(r.data)};
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
  }

  Future<void> changeStatus(String value) async {
    await ApiClient.instance.dio.patch('/users/me/status', data: {'status': value});
    if (mounted) setState(() => status = value);
  }

  Future<void> changeAvatar() async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (x == null) return;
    setState(() => uploading = true);
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(x.path, filename: x.name)});
      final upload = await ApiClient.instance.dio.post('/media/upload', data: form);
      final r = await ApiClient.instance.dio.patch('/users/me', data: {'avatarUrl': upload.data['url']});
      me = {...?me, ...Map<String, dynamic>.from(r.data)};
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final avatar = ApiClient.absoluteMediaUrl(me?['avatarUrl']);
    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 62,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? const Icon(Icons.person, size: 64) : null,
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: IconButton.filled(
                    onPressed: uploading ? null : changeAvatar,
                    icon: uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_camera),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          TextField(controller: displayName, decoration: const InputDecoration(labelText: 'Nome de exibição', prefixIcon: Icon(Icons.badge))),
          const SizedBox(height: 14),
          TextField(controller: personalMsg, maxLength: 100, decoration: const InputDecoration(labelText: 'Mensagem pessoal', prefixIcon: Icon(Icons.edit_note))),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'ONLINE', child: Text('🟢 Online')),
              DropdownMenuItem(value: 'AWAY', child: Text('🟡 Ausente')),
              DropdownMenuItem(value: 'BUSY', child: Text('🔴 Ocupado')),
              DropdownMenuItem(value: 'INVISIBLE', child: Text('⚪ Invisível')),
            ],
            onChanged: (v) { if (v != null) changeStatus(v); },
          ),
          const SizedBox(height: 22),
          SizedBox(height: 52, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Salvar perfil'))),
          const SizedBox(height: 28),
          const ListTile(leading: Icon(Icons.palette), title: Text('Tema'), subtitle: Text('MSN Azul • V4')),
          const ListTile(leading: Icon(Icons.notifications_active), title: Text('Notificações'), subtitle: Text('Estrutura preparada para FCM/APNs')),
          const ListTile(leading: Icon(Icons.shield), title: Text('Privacidade'), subtitle: Text('Controles avançados entram na próxima etapa')),
        ],
      ),
    );
  }
}
