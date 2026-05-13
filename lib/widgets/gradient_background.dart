import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Full-screen gradient with soft decorative blobs.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppTheme.pageGradient),
        ),
        const _Blob(
          top: -80,
          left: -60,
          size: 280,
          color: Color(0x332563EB),
        ),
        const _Blob(
          bottom: 100,
          right: -80,
          size: 320,
          color: Color(0x330D9488),
        ),
        const _Blob(
          top: 200,
          right: -40,
          size: 180,
          color: Color(0x22F43F5E),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: math.pi / 6,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
