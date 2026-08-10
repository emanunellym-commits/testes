import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  List<dynamic> stories = [];
  bool loading = true;
  bool uploading = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final r = await ApiClient.instance.dio.get('/stories');
    if (!mounted) return;
    setState(() {
      stories = List<dynamic>.from(r.data);
      loading = false;
    });
  }

  Future<Map<String, dynamic>> upload(String path, String name) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: name),
    });
    final r = await ApiClient.instance.dio.post('/media/upload', data: form);
    return Map<String, dynamic>.from(r.data);
  }

  Future<void> createTextStory() async {
    final c = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo status'),
        content: TextField(
          controller: c,
          maxLength: 180,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'O que você está pensando?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              await ApiClient.instance.dio.post('/stories', data: {
                'text': c.text.trim(),
              });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              await load();
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  Future<void> createMediaStory(bool video) async {
    final x = video
        ? await picker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 1),
          )
        : await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 88,
          );

    if (x == null) return;

    setState(() => uploading = true);
    try {
      final uploaded = await upload(x.path, x.name);
      await ApiClient.instance.dio.post('/stories', data: {
        'mediaUrl': uploaded['url'],
        'mediaType': video ? 'VIDEO' : 'IMAGE',
      });
      await load();
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> viewStory(dynamic s) async {
    await ApiClient.instance.dio.post('/stories/${s['id']}/view');

    if (!mounted) return;
    final mediaUrl = ApiClient.absoluteMediaUrl(s['mediaUrl']);

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(18),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s['user']['displayName'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (s['mediaType'] == 'IMAGE' && mediaUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    mediaUrl,
                    height: 420,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (s['mediaType'] == 'VIDEO')
                Container(
                  height: 260,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.black26,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, size: 70),
                      SizedBox(height: 10),
                      Text('Vídeo do status'),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0878FF), Color(0xFF0E3B81)],
                    ),
                  ),
                  child: Text(
                    s['text'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> createMenu() async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Status de texto'),
              onTap: () {
                Navigator.pop(sheetContext);
                createTextStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Status com foto'),
              onTap: () {
                Navigator.pop(sheetContext);
                createMediaStory(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Status com vídeo'),
              onTap: () {
                Navigator.pop(sheetContext);
                createMediaStory(true);
              },
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
        title: const Text('Status'),
        actions: [
          IconButton(
            onPressed: createMenu,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: Stack(
        children: [
          loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: load,
                  child: stories.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const SizedBox(height: 120),
                            const Center(
                              child: Text(
                                'Nenhum status ainda.',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: createMenu,
                              icon: const Icon(Icons.add),
                              label: const Text('Criar status'),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: stories.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = stories[i];
                            final seen =
                                (s['views'] as List?)?.isNotEmpty == true;

                            return Card(
                              child: ListTile(
                                onTap: () => viewStory(s),
                                leading: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 2,
                                      color: seen
                                          ? Colors.grey
                                          : Colors.lightBlueAccent,
                                    ),
                                  ),
                                  child: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                ),
                                title: Text(
                                  s['user']['displayName'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  s['mediaType'] == 'IMAGE'
                                      ? '📷 Foto'
                                      : s['mediaType'] == 'VIDEO'
                                          ? '🎥 Vídeo'
                                          : (s['text'] ?? 'Status'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            );
                          },
                        ),
                ),
          if (uploading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createMenu,
        child: const Icon(Icons.add),
      ),
    );
  }
}
