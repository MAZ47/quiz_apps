import 'package:flutter/material.dart';

/// Simple circular avatar with a flag badge in the corner, matching the
/// reference design (optionally with a crown for 1st place).
class LeaderAvatar extends StatelessWidget {
  final Color backgroundColor;
  final IconData icon;
  final String flagEmoji;
  final bool showCrown;
  final double radius;

  const LeaderAvatar({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.flagEmoji,
    this.showCrown = false,
    this.radius = 38,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + 10,
      height: radius * 2 + (showCrown ? 34 : 10),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: showCrown ? 30 : 0,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: radius,
                  backgroundColor: backgroundColor,
                  child: Icon(icon, size: radius, color: Colors.black87),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Text(flagEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ],
            ),
          ),
          if (showCrown)
            const Positioned(
              top: 0,
              child: Text('👑', style: TextStyle(fontSize: 30)),
            ),
        ],
      ),
    );
  }
}
