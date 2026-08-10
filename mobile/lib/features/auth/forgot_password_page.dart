import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  final code = TextEditingController();
  final newPassword = TextEditingController();
  int step = 0;
  bool loading = false;

  Future<void> request() async {
    setState(() => loading = true);
    try {
      await ApiClient.instance.dio.post('/account/forgot-password', data: {
        'email': email.text.trim().toLowerCase(),
      });
      if (mounted) setState(() => step = 1);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> reset() async {
    setState(() => loading = true);
    try {
      await ApiClient.instance.dio.post('/account/reset-password', data: {
        'email': email.text.trim().toLowerCase(),
        'token': code.text.trim(),
        'newPassword': newPassword.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha alterada. Você já pode entrar.')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.lock_reset_rounded, size: 70),
          const SizedBox(height: 22),
          TextField(
            controller: email,
            enabled: step == 0,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          if (step == 1) ...[
            const SizedBox(height: 14),
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'Código recebido',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassword,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                prefixIcon: Icon(Icons.password),
              ),
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(
            onPressed: loading ? null : (step == 0 ? request : reset),
            child: Text(
              loading
                  ? 'Aguarde...'
                  : step == 0
                      ? 'Enviar código'
                      : 'Alterar senha',
            ),
          ),
        ],
      ),
    );
  }
}
