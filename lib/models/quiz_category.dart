import 'package:flutter/material.dart';

class QuizCategory {
  final String name;          // ক্যাটাগরির নাম
  final int questionCount;    // এই ক্যাটাগরিতে মোট প্রশ্নের সংখ্যা
  final IconData icon;        // ক্যাটাগরির জন্য নির্দিষ্ট ফ্ল্যাটার আইকন
  final Color color;          // ক্যাটাগরির থিম কালার
  final String imageUrl;      // ক্যাটাগরির জন্য ইমেজ বা ব্যানারের লিংক

  QuizCategory({
    required this.name,
    required this.questionCount,
    required this.icon,
    required this.color,
    required this.imageUrl,
  });
}