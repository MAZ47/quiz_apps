import 'package:flutter/material.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? currentImageUrl;
  final bool isLoading;
  final VoidCallback? onEditTap;
  final double radius;

  const ProfileImageWidget({
    super.key,
    this.currentImageUrl,
    this.isLoading = false,
    this.onEditTap,
    this.radius = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onEditTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: const Color(0xFFF0EFFF),
              backgroundImage: currentImageUrl != null && !isLoading
                  ? NetworkImage(currentImageUrl!)
                  : null,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : (currentImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: radius * 1.1,
                            color: const Color(0xFF6B58E9),
                          )
                        : null),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF6B58E9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Icon(Icons.edit, size: radius * 0.3, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
