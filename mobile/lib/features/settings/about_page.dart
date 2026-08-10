import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o LiveChat')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const CircleAvatar(
            radius: 55,
            child: Icon(Icons.chat_bubble_rounded, size: 52),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'LiveChat Messenger',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
          const Center(child: Text('Versão 0.9.0 (V9)')),
          const SizedBox(height: 28),
          const Text(
            'Um mensageiro moderno com inspiração nostálgica nos comunicadores clássicos dos anos 2000.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Política de Privacidade'),
            subtitle: Text('Veja PRIVACY_POLICY.md no projeto'),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Termos de Uso'),
            subtitle: Text('Veja TERMS_OF_USE.md no projeto'),
          ),
        ],
      ),
    );
  }
}
