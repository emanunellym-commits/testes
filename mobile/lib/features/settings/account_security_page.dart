import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  Future<void> verifyEmail() async {
    await ApiClient.instance.dio.post('/account/verification/send');

    if (!mounted) return;
    final c = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Verificar e-mail'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Código recebido por e-mail',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              await ApiClient.instance.dio.post(
                '/account/verification/confirm',
                data: {'token': c.text.trim()},
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-mail verificado.')),
                );
              }
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteAccount() async {
    final password = TextEditingController();
    final code = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A exclusão desativa a conta e remove dados pessoais do perfil. Esta ação é séria.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirme sua senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiClient.instance.dio.post('/account/delete/request', data: {
      'password': password.text,
    });

    if (!mounted) return;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmação final'),
        content: TextField(
          controller: code,
          decoration: const InputDecoration(
            labelText: 'Código enviado por e-mail',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir conta'),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    await ApiClient.instance.dio.post('/account/delete/confirm', data: {
      'token': code.text.trim(),
    });

    await ApiClient.instance.logout();

    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e segurança')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Verificar e-mail'),
              subtitle: const Text('Confirme que o endereço pertence a você'),
              onTap: verifyEmail,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Recuperação de senha'),
              subtitle: const Text('Enviar código para redefinir a senha'),
              onTap: () => context.push('/forgot-password'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Autenticação em dois fatores'),
              subtitle: const Text('Proteja a conta com código TOTP'),
              onTap: () => context.push('/settings/2fa'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('Verificar telefone'),
              subtitle: const Text('Preparado para confirmação via SMS'),
              onTap: () => context.push('/settings/phone'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Dispositivos e sessões'),
              subtitle: const Text('Veja e encerre sessões conectadas'),
              onTap: () => context.push('/settings/sessions'),
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Excluir minha conta'),
              subtitle: const Text('Desativar permanentemente seu perfil'),
              onTap: deleteAccount,
            ),
          ),
        ],
      ),
    );
  }
}
