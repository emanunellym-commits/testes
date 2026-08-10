import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    this.reportedUserId,
    this.conversationId,
    this.messageId,
  });

  final String? reportedUserId;
  final String? conversationId;
  final String? messageId;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String reason = 'SPAM';
  final details = TextEditingController();
  bool sending = false;

  Future<void> send() async {
    setState(() => sending = true);
    try {
      await ApiClient.instance.dio.post('/reports', data: {
        'reportedUserId': widget.reportedUserId,
        'conversationId': widget.conversationId,
        'messageId': widget.messageId,
        'reason': reason,
        'details': details.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denúncia enviada para análise.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const reasons = {
      'SPAM': 'Spam',
      'HARASSMENT': 'Assédio',
      'IMPERSONATION': 'Falsa identidade',
      'ILLEGAL_CONTENT': 'Conteúdo ilegal',
      'SEXUAL_CONTENT': 'Conteúdo sexual impróprio',
      'VIOLENCE': 'Violência',
      'OTHER': 'Outro',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Denunciar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: reason,
            decoration: const InputDecoration(labelText: 'Motivo'),
            items: reasons.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => reason = v ?? reason),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: details,
            maxLines: 5,
            maxLength: 800,
            decoration: const InputDecoration(
              labelText: 'Detalhes',
              hintText: 'Explique o que aconteceu...',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: sending ? null : send,
            child: Text(sending ? 'Enviando...' : 'Enviar denúncia'),
          ),
        ],
      ),
    );
  }
}
