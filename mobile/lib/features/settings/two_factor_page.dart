import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class TwoFactorPage extends StatefulWidget {
  const TwoFactorPage({super.key});

  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  String? secret;
  final token = TextEditingController();
  List<String> recoveryCodes = [];
  bool loading = false;

  Future<void> setup() async {
    setState(() => loading = true);
    try {
      final r = await ApiClient.instance.dio.post('/2fa/setup');
      if (mounted) setState(() => secret = r.data['secret']);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> enable() async {
    setState(() => loading = true);
    try {
      final r = await ApiClient.instance.dio.post(
        '/2fa/enable',
        data: {'token': token.text.trim()},
      );

      if (mounted) {
        setState(() {
          recoveryCodes =
              List<String>.from(r.data['recoveryCodes'] ?? []);
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autenticação em dois fatores'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Icon(Icons.security_rounded, size: 74),
          const SizedBox(height: 22),
          if (secret == null)
            FilledButton(
              onPressed: loading ? null : setup,
              child: const Text('Configurar 2FA'),
            )
          else ...[
            const Text('Chave para seu aplicativo autenticador:'),
            const SizedBox(height: 8),
            SelectableText(secret!),
            const SizedBox(height: 18),
            TextField(
              controller: token,
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: loading ? null : enable,
              child: const Text('Ativar 2FA'),
            ),
          ],
          if (recoveryCodes.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Códigos de recuperação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Salve em local seguro. Cada código funciona uma vez.',
            ),
            const SizedBox(height: 10),
            ...recoveryCodes.map(
              (code) => Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: SelectableText(code),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
