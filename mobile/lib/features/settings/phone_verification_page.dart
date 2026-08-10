import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';

class PhoneVerificationPage extends StatefulWidget {
  const PhoneVerificationPage({super.key});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final phone = TextEditingController();
  final code = TextEditingController();
  int step = 0;
  bool loading = false;

  Future<void> send() async {
    setState(() => loading = true);
    try {
      await ApiClient.instance.dio.post('/phone/send-code', data: {
        'phone': phone.text.trim(),
      });
      if (mounted) setState(() => step = 1);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> confirm() async {
    setState(() => loading = true);
    try {
      await ApiClient.instance.dio.post('/phone/confirm', data: {
        'code': code.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefone verificado.')),
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
      appBar: AppBar(title: const Text('Verificar telefone')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          TextField(
            controller: phone,
            enabled: step == 0,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone com DDD',
              hintText: '+55 11 99999-9999',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          if (step == 1) ...[
            const SizedBox(height: 14),
            TextField(
              controller: code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código recebido por SMS',
                prefixIcon: Icon(Icons.sms_outlined),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : (step == 0 ? send : confirm),
            child: Text(step == 0 ? 'Enviar código' : 'Confirmar'),
          ),
        ],
      ),
    );
  }
}
