import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../calls/call_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    this.isGroup = false,
  });

  final String conversationId;
  final String contactName;
  final bool isGroup;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final socketService = SocketService.instance;
  final picker = ImagePicker();
  final recorder = AudioRecorder();

  List<dynamic> messages = [];
  String? meId;
  bool typing = false;
  bool uploading = false;
  bool recording = false;
  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final me = await ApiClient.instance.dio.get('/auth/me');
    final history = await ApiClient.instance.dio
        .get('/conversations/${widget.conversationId}/messages');

    if (mounted) {
      setState(() {
        meId = me.data['id'];
        messages = List<dynamic>.from(history.data);
      });
    }

    final socket = await socketService.connect();
    socketService.join(widget.conversationId);

    socket.on('call.invite', incomingCall);

    socket.on('message.new', (data) {
      if (data['conversationId'] == widget.conversationId && mounted) {
        setState(() => messages.add(data));
      }
    });

    socket.on('nudge', (data) {
      if (data['conversationId'] == widget.conversationId && mounted) {
        setState(() => messages.add(data));
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⭐ ${widget.contactName} chamou sua atenção!'),
          ),
        );
      }
    });

    socket.on('typing', (data) {
      if (data['conversationId'] == widget.conversationId &&
          data['userId'] != meId &&
          mounted) {
        setState(() => typing = data['typing'] == true);
      }
    });
  }

  Future<void> incomingCall(dynamic data) async {
    if (!mounted || data is! Map || data['conversationId'] != widget.conversationId) return;
    final callId = data['callId']?.toString();
    if (callId == null) return;
    final video = data['video'] == true;

    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(video ? '📹 Videochamada' : '📞 Chamada de voz'),
        content: Text('${widget.contactName} está ligando.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Recusar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Atender'),
          ),
        ],
      ),
    );

    if (accept == true && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallPage(
            conversationId: widget.conversationId,
            peerName: widget.contactName,
            callId: callId,
            video: video,
            isCaller: false,
          ),
        ),
      );
    } else {
      socketService.socket?.emit('call.reject', {
        'conversationId': widget.conversationId,
        'callId': callId,
        'video': video,
      });
    }
  }

  Future<void> startCall(bool video) async {
    final callId = '${DateTime.now().millisecondsSinceEpoch}-${widget.conversationId.hashCode.abs()}';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallPage(
          conversationId: widget.conversationId,
          peerName: widget.contactName,
          callId: callId,
          video: video,
          isCaller: true,
        ),
      ),
    );
  }

  void send() {
    final text = input.text.trim();
    if (text.isEmpty) return;

    socketService.socket?.emit('message.send', {
      'conversationId': widget.conversationId,
      'text': text,
      'type': 'TEXT',
    });

    input.clear();
    stopTyping();
  }

  void startTyping() {
    socketService.socket?.emit('typing', {
      'conversationId': widget.conversationId,
      'typing': true,
    });

    typingTimer?.cancel();
    typingTimer = Timer(const Duration(milliseconds: 1200), stopTyping);
  }

  void stopTyping() {
    typingTimer?.cancel();
    socketService.socket?.emit('typing', {
      'conversationId': widget.conversationId,
      'typing': false,
    });
  }

  void nudge() {
    socketService.socket?.emit('nudge', {
      'conversationId': widget.conversationId,
    });
    HapticFeedback.mediumImpact();
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    String? originalName,
  }) async {
    final file = File(path);
    final filename = originalName ?? file.uri.pathSegments.last;

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(path, filename: filename),
    });

    final r = await ApiClient.instance.dio.post('/media/upload', data: form);
    return Map<String, dynamic>.from(r.data);
  }

  void emitMedia(Map<String, dynamic> uploaded, String type) {
    socketService.socket?.emit('message.send', {
      'conversationId': widget.conversationId,
      'type': type,
      'mediaUrl': uploaded['url'],
      'mediaName': uploaded['name'],
      'mediaMime': uploaded['mime'],
      'mediaSize': uploaded['size'],
    });
  }

  Future<void> sendImage() async {
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    await uploadAndSend(x.path, 'IMAGE', x.name);
  }

  Future<void> sendCamera() async {
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    await uploadAndSend(x.path, 'IMAGE', x.name);
  }

  Future<void> sendVideo() async {
    final x = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (x == null) return;
    await uploadAndSend(x.path, 'VIDEO', x.name);
  }

  Future<void> sendDocument() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    final path = result?.files.single.path;
    if (path == null) return;

    await uploadAndSend(
      path,
      'FILE',
      result!.files.single.name,
    );
  }

  Future<void> uploadAndSend(
    String path,
    String type,
    String originalName,
  ) async {
    setState(() => uploading = true);
    try {
      final uploaded = await uploadFile(path, originalName: originalName);
      emitMedia(uploaded, type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível enviar o arquivo.')),
        );
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> toggleRecording() async {
    if (recording) {
      final path = await recorder.stop();
      if (mounted) setState(() => recording = false);

      if (path != null) {
        await uploadAndSend(path, 'AUDIO', 'audio-${DateTime.now().millisecondsSinceEpoch}.m4a');
      }
      return;
    }

    if (!await recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissão de microfone negada.')),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/livechat-${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    if (mounted) setState(() => recording = true);
  }

  Future<void> openMedia(String? rawUrl) async {
    final url = ApiClient.absoluteMediaUrl(rawUrl);
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String fileSize(dynamic bytes) {
    final n = bytes is int ? bytes : int.tryParse('$bytes') ?? 0;
    if (n < 1024) return '$n B';
    if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
    return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Widget messageContent(dynamic m) {
    final type = m['type']?.toString() ?? 'TEXT';
    final mediaUrl = ApiClient.absoluteMediaUrl(m['mediaUrl']);

    if (type == 'IMAGE' && mediaUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () => openMedia(m['mediaUrl']),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            mediaUrl,
            width: 240,
            height: 230,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 220,
              height: 100,
              child: Center(child: Text('Imagem indisponível')),
            ),
          ),
        ),
      );
    }

    if (type == 'AUDIO') {
      return InkWell(
        onTap: () => openMedia(m['mediaUrl']),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(child: Icon(Icons.play_arrow)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mensagem de voz'),
                Text(
                  fileSize(m['mediaSize']),
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (type == 'VIDEO') {
      return InkWell(
        onTap: () => openMedia(m['mediaUrl']),
        child: const SizedBox(
          width: 220,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded, size: 54),
              SizedBox(height: 8),
              Text('Abrir vídeo'),
            ],
          ),
        ),
      );
    }

    if (type == 'FILE') {
      return InkWell(
        onTap: () => openMedia(m['mediaUrl']),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, size: 34),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['mediaName'] ?? 'Arquivo',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    fileSize(m['mediaSize']),
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'SYSTEM') {
      return Text(
        m['body'] ?? '',
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return Text(m['body'] ?? '');
  }

  Future<void> attachments() async {
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 18,
            children: [
              _AttachmentButton(
                icon: Icons.image,
                label: 'Galeria',
                onTap: () {
                  Navigator.pop(sheetContext);
                  sendImage();
                },
              ),
              _AttachmentButton(
                icon: Icons.photo_camera,
                label: 'Câmera',
                onTap: () {
                  Navigator.pop(sheetContext);
                  sendCamera();
                },
              ),
              _AttachmentButton(
                icon: Icons.videocam,
                label: 'Vídeo',
                onTap: () {
                  Navigator.pop(sheetContext);
                  sendVideo();
                },
              ),
              _AttachmentButton(
                icon: Icons.description,
                label: 'Documento',
                onTap: () {
                  Navigator.pop(sheetContext);
                  sendDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    recorder.dispose();
    socketService.socket?.off('call.invite', incomingCall);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Icon(widget.isGroup ? Icons.groups_rounded : Icons.person),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.contactName),
                Text(
                  typing
                      ? 'digitando...'
                      : widget.isGroup
                          ? 'Grupo LiveChat'
                          : 'LiveChat',
                  style: TextStyle(
                    fontSize: 12,
                    color: typing ? Colors.greenAccent : Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Buscar no chat',
            onPressed: () {
              final name = Uri.encodeQueryComponent(widget.contactName);
              context.push('/chat-search/${widget.conversationId}?name=$name');
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Chamada de voz',
            onPressed: widget.isGroup ? null : () => startCall(false),
            icon: const Icon(Icons.call),
          ),
          IconButton(
            tooltip: 'Videochamada',
            onPressed: widget.isGroup ? null : () => startCall(true),
            icon: const Icon(Icons.videocam),
          ),
        ],
      ),
      body: Column(
        children: [
          if (uploading)
            const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                final me = m['senderId'] == meId;
                final isNudge = m['type'] == 'NUDGE';
                final isSystem = m['type'] == 'SYSTEM';

                if (isNudge) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('⭐ Chamar Atenção!'),
                    ),
                  );
                }

                if (isSystem) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        m['body'] ?? '',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 290),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: me
                          ? const Color(0xFF0878FF)
                          : const Color(0xFF243B5D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: messageContent(m),
                  ),
                );
              },
            ),
          ),
          if (recording)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                '🔴 Gravando áudio... toque no microfone para enviar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Chamar atenção',
                  onPressed: nudge,
                  icon: const Icon(Icons.star_rounded, color: Colors.amber),
                ),
                IconButton(
                  tooltip: 'Anexar',
                  onPressed: attachments,
                  icon: const Icon(Icons.add_circle_outline),
                ),
                Expanded(
                  child: TextField(
                    controller: input,
                    onChanged: (_) => startTyping(),
                    onSubmitted: (_) => send(),
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem...',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: recording ? 'Parar e enviar áudio' : 'Gravar áudio',
                  onPressed: toggleRecording,
                  icon: Icon(
                    recording ? Icons.stop_circle : Icons.mic_rounded,
                    color: recording ? Colors.redAccent : null,
                  ),
                ),
                IconButton(
                  onPressed: send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                child: Icon(icon),
              ),
              const SizedBox(height: 7),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
