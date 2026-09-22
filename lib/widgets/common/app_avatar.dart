import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.radius = 40,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.inputBackground,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Icon(
                    Icons.person,
                    size: radius * 1.2,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  )
                : null,
          ),
          if (onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
