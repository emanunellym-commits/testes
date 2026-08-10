import 'package:flutter/material.dart';

class IncomingCallPage extends StatelessWidget {
  const IncomingCallPage({
    super.key,
    required this.callerName,
    required this.video,
    required this.onAccept,
    required this.onReject,
  });

  final String callerName;
  final bool video;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 72,
                child: Icon(Icons.person, size: 78),
              ),
              const SizedBox(height: 28),
              Text(
                callerName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                video ? 'Videochamada recebida' : 'Chamada recebida',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 55),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallAction(
                    icon: Icons.call_end,
                    label: 'Recusar',
                    background: Colors.redAccent,
                    onTap: onReject,
                  ),
                  _CallAction(
                    icon: video ? Icons.videocam : Icons.call,
                    label: 'Atender',
                    background: Colors.green,
                    onTap: onAccept,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(45),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: background,
            child: Icon(icon, size: 34, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(label),
      ],
    );
  }
}
