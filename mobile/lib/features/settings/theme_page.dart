import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key, required this.controller});

  final LiveChatThemeController controller;

  @override
  Widget build(BuildContext context) {
    final themes = [
      ('classic_blue', 'Clássico Azul', 'Azul profundo e nostálgico', Icons.water_drop_rounded),
      ('aqua_2000', 'Aqua 2000', 'Claro e inspirado nos mensageiros antigos', Icons.blur_on_rounded),
      ('night', 'Noturno', 'Visual escuro suave', Icons.dark_mode_rounded),
      ('neon', 'Neon', 'Azul elétrico moderno', Icons.bolt_rounded),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Temas')),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: themes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final t = themes[i];
            final selected = controller.themeKey == t.$1;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(t.$4)),
                title: Text(t.$2),
                subtitle: Text(t.$3),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: Colors.greenAccent)
                    : const Icon(Icons.chevron_right),
                onTap: () => controller.setTheme(t.$1),
              ),
            );
          },
        ),
      ),
    );
  }
}
