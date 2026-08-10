import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final twoFactor = TextEditingController();

  bool requiresTwoFactor = false;
  bool useRecoveryCode = false;
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ApiClient.instance.ensureDeviceId();

      final response = await ApiClient.instance.dio.post(
        '/auth/login',
        data: {
          'email': email.text.trim(),
          'password': password.text,
          'deviceId': await ApiClient.instance.deviceId(),
          'deviceName': 'LiveChat Mobile',
          'platform': 'mobile',
          if (requiresTwoFactor && !useRecoveryCode)
            'twoFactorToken': twoFactor.text.trim(),
          if (requiresTwoFactor && useRecoveryCode)
            'recoveryCode': twoFactor.text.trim(),
        },
      );

      if (response.data['requiresTwoFactor'] == true) {
        if (mounted) {
          setState(() => requiresTwoFactor = true);
        }
        return;
      }

      await ApiClient.instance.saveSession(
        accessToken: response.data['accessToken'],
        refreshToken: response.data['refreshToken'],
      );

      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          error = 'Não foi possível entrar. Confira seus dados.';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 92,
                    color: Color(0xFF1B8CFF),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'LiveChat',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Messenger',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.lightBlueAccent,
                    ),
                  ),
                  const SizedBox(height: 42),
                  TextField(
                    controller: email,
                    enabled: !requiresTwoFactor,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    enabled: !requiresTwoFactor,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  if (requiresTwoFactor) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: twoFactor,
                      decoration: InputDecoration(
                        labelText: useRecoveryCode
                            ? 'Código de recuperação'
                            : 'Código do autenticador',
                        prefixIcon: const Icon(Icons.security),
                      ),
                    ),
                    SwitchListTile(
                      value: useRecoveryCode,
                      onChanged: (v) =>
                          setState(() => useRecoveryCode = v),
                      title: const Text('Usar código de recuperação'),
                    ),
                  ],
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: Text(
                        loading
                            ? 'Entrando...'
                            : requiresTwoFactor
                                ? 'Confirmar segurança'
                                : 'Entrar',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Esqueci minha senha'),
                  ),
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Criar uma conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
