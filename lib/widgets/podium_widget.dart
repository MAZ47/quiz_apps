import 'package:flutter/material.dart';
import 'package:quiz_apps/models/scoreboard_entry.dart';

import 'leader_avatar.dart';
import 'podium_block.dart';

class PodiumWidget extends StatelessWidget {
  final List<ScoreboardEntry> topUsers;

  const PodiumWidget({super.key, required this.topUsers});

  @override
  Widget build(BuildContext context) {
    final firstPlace = topUsers.isNotEmpty ? topUsers[0] : null;
    final secondPlace = topUsers.length > 1 ? topUsers[1] : null;
    final thirdPlace = topUsers.length > 2 ? topUsers[2] : null;

    final podiumColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final podiumHeight = constraints.maxHeight.isInfinite
            ? constraints.maxWidth * 0.5
            : constraints.maxHeight * 0.5;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 2nd place
                  PodiumBlock(
                    color: podiumColor,
                    height: podiumHeight * 0.7,
                    width: constraints.maxWidth / 3,
                    position: 2,
                    qp: secondPlace?.correctCount ?? 0,
                    avatar: const LeaderAvatar(
                      backgroundColor: Color(0xFFFBD9E6),
                      icon: Icons.face_3,
                      flagEmoji: '🇫🇷',
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 1st place (the one the painter is dynamic enough to make
                  // taller + wider + with a crown, just by changing inputs)
                  PodiumBlock(
                    color: podiumColor,
                    height: podiumHeight,
                    width: constraints.maxWidth / 3,
                    position: 1,
                    qp: firstPlace?.correctCount ?? 0,
                    avatar: const LeaderAvatar(
                      backgroundColor: Color(0xFFCFF3E8),
                      icon: Icons.face,
                      flagEmoji: '🇵🇹',
                      showCrown: true,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 3rd place
                  PodiumBlock(
                    color: podiumColor,
                    height: podiumHeight * 0.5,
                    width: constraints.maxWidth / 3,
                    position: 3,
                    qp: thirdPlace?.correctCount ?? 0,
                    avatar: const LeaderAvatar(
                      backgroundColor: Color(0xFFD6E4FB),
                      icon: Icons.face_4,
                      flagEmoji: '🇨🇦',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
