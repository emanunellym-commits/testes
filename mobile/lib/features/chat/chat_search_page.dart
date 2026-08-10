import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({
    super.key,
    required this.conversationId,
    required this.title,
  });

  final String conversationId;
  final String title;

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final q = TextEditingController();
  List<dynamic> results = [];
  bool loading = false;

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (q.text.trim().isEmpty) return;
    setState(() => loading = true);

    try {
      final r = await ApiClient.instance.dio.get(
        '/conversations/${widget.conversationId}/messages',
        queryParameters: {'q': q.text.trim()},
      );

      if (!mounted) return;
      setState(() => results = List<dynamic>.from(r.data));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar em ${widget.title}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              controller: q,
              autofocus: true,
              onSubmitted: (_) => search(),
              decoration: InputDecoration(
                hintText: 'Pesquisar mensagem...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('Digite algo para pesquisar no chat.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m = results[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(
                            m['body'] ?? '[mídia]',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            m['createdAt']?.toString() ?? '',
                            maxLines: 1,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
