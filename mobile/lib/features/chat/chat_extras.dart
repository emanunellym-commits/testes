import 'package:flutter/material.dart';

String receiptMark(dynamic message) {
  final receipts = List<dynamic>.from(message['receipts'] ?? []);
  if (receipts.isEmpty) return '✓';

  final anyRead = receipts.any((r) => r['status'] == 'READ');
  if (anyRead) return '✓✓';

  final anyDelivered = receipts.any((r) => r['status'] == 'DELIVERED');
  if (anyDelivered) return '✓✓';

  return '✓';
}

Widget reactionRow(dynamic message) {
  final reactions = List<dynamic>.from(message['reactions'] ?? []);
  if (reactions.isEmpty) return const SizedBox.shrink();

  final grouped = <String, int>{};
  for (final r in reactions) {
    final emoji = r['emoji']?.toString() ?? '';
    if (emoji.isEmpty) continue;
    grouped[emoji] = (grouped[emoji] ?? 0) + 1;
  }

  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: grouped.entries
        .map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black26,
            ),
            child: Text('${e.key} ${e.value}'),
          ),
        )
        .toList(),
  );
}
