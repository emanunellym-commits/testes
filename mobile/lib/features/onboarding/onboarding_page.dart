import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const storage = FlutterSecureStorage();

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final controller = PageController();
  int page = 0;

  final items = const [
    (
      Icons.chat_bubble_rounded,
      'Converse do seu jeito',
      'Mensagens em tempo real, grupos, fotos, vídeos, áudios e documentos.'
    ),
    (
      Icons.star_rounded,
      'Nostalgia reinventada',
      'Status, temas e o clássico Chamar Atenção com uma experiência moderna.'
    ),
    (
      Icons.video_call_rounded,
      'Perto de quem importa',
      'Chamadas de voz e vídeo, notificações e presença online em um só lugar.'
    ),
  ];

  Future<void> finish() async {
    await OnboardingPage.storage.write(key: 'onboarding_done', value: '1');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: items.length,
                onPageChanged: (v) => setState(() => page = v),
                itemBuilder: (_, i) {
                  final item = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 145,
                          height: 145,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(38),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A78FF), Color(0xFF0D3B82)],
                            ),
                          ),
                          child: Icon(item.$1, size: 74, color: Colors.white),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          item.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.$3,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                items.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == page ? 28 : 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: i == page
                        ? Colors.lightBlueAccent
                        : Colors.white24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    if (page == items.length - 1) {
                      finish();
                    } else {
                      controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(
                    page == items.length - 1 ? 'Começar' : 'Continuar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
