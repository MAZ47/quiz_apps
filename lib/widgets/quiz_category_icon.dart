import 'package:flutter/material.dart';

class QuizCategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const QuizCategoryIcon({
    super.key,
    required this.icon,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color, size: 32);
  }
}
