import 'package:flutter/material.dart';
import '../theme.dart';

/// Pulsing placeholder shown while real content streams in from the backend.
/// The shared animation fades the block in and out so skeletons feel alive
/// without adding any third-party shimmer dependency.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.child, this.baseColor});

  final Widget? child;
  final Color? baseColor;

  /// A rounded block placeholder.
  static Widget box({
    double? width,
    double height = 14,
    double radius = AppRadius.sm,
  }) {
    return AppSkeleton(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  /// A circular placeholder (avatars, icon tiles).
  static Widget circle({double size = 40}) {
    return AppSkeleton(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: widget.child ??
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: widget.baseColor ?? AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
    );
  }
}