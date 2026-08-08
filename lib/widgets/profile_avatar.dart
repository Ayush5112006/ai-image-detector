import 'package:flutter/material.dart';
import '../theme.dart';

/// A tappable circular profile picture. Tapping it opens the
/// Profile Details page by default.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.size = 42,
    this.name,
    this.onTap,
  });

  final double size;
  final String? name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String initial = (name == null || name!.isEmpty)
        ? ''
        : name!.trim()[0].toUpperCase();
    final VoidCallback? handler = onTap;

    return GestureDetector(
      onTap: handler,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: size > 50 ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: size > 50 ? 10 : 6,
                  offset: Offset(0, size > 50 ? 4 : 2),
                ),
              ],
            ),
            child: Center(
              child: initial.isEmpty
                  ? Icon(
                      Icons.person,
                      color: Colors.white,
                      size: size * 0.5,
                    )
                  : Text(
                      initial,
                      style: TextStyle(
                        fontSize: size * 0.45,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(size * 0.06),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.verified,
                color: AppColors.primary,
                size: size * 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
