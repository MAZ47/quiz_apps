import 'package:flutter/material.dart';

import 'podium_painter.dart';

/// A ready-to-use widget that stacks the QP badge + CustomPaint block
/// together, so you can just do:
///
/// ```dart
/// PodiumBlock(color: Colors.deepPurple, height: 300, position: 1, qp: 2569)
/// ```
class PodiumBlock extends StatelessWidget {
  final Color color;
  final double height;
  final double width;
  final int position;
  final int? qp;
  final Widget? avatar;
  final double depth;

  const PodiumBlock({
    super.key,
    required this.color,
    required this.height,
    required this.position,
    this.width = 130,
    this.qp,
    this.avatar,
    this.depth = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (avatar != null) ...[avatar!, const SizedBox(height: 10)],
        if (qp != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '${_formatQp(qp!)} QP',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        CustomPaint(
          size: Size(width, height),
          painter: PodiumPainter(
            color: color,
            position: position,
            depth: depth,
          ),
        ),
      ],
    );
  }

  String _formatQp(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
