import 'package:flutter/material.dart';

class LoadingIndicator extends StatefulWidget {
  const LoadingIndicator({
    super.key,
    this.size,
  });

  final double? size;

  @override
  _LoadingIndicatorState createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController loadingController;
  late Animation<double> rotationAnimation;
  late Animation<double> scaleAnimation;

  @override
  void initState() {
    super.initState();
    loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159265359)
        .animate(loadingController);
    scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(loadingController);
  }

  @override
  void dispose() {
    loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loadingController,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'logo/logo.png',
        width: widget.size ?? 75,
        height: widget.size ?? 75,
      ),
    );
  }
}
