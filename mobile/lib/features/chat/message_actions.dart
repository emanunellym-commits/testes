import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

Future<void> showMessageActions({
  required BuildContext context,
  required dynamic message,
  required bool isMine,
  required String conversationId,
  required VoidCallback onReply,
  required VoidCallback onForward,
  required VoidCallback onRefresh,
  required void Function(String emoji) onReact,
}) async {
  const emojis = ['❤️', '😂', '😮', '😢', '👍', '🔥'];

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: emojis
                    .map(
                      (emoji) => InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          onReact(emoji);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 27),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Responder'),
              onTap: () {
                Navigator.pop(sheetContext);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Encaminhar'),
              onTap: () {
                Navigator.pop(sheetContext);
                onForward();
              },
            ),
            if (isMine && message['type'] == 'TEXT')
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final c =
                      TextEditingController(text: message['body'] ?? '');
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Editar mensagem'),
                      content: TextField(
                        controller: c,
                        autofocus: true,
                        maxLines: 4,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await ApiClient.instance.dio.patch(
                              '/messages/${message['id']}',
                              data: {'text': c.text.trim()},
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            onRefresh();
                          },
                          child: const Text('Salvar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text('Apagar'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await ApiClient.instance.dio
                      .delete('/messages/${message['id']}');
                  onRefresh();
                },
              ),
          ],
        ),
      ),
    ),
  );
}
