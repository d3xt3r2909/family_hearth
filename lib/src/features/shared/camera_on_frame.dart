import 'package:flutter/material.dart';

class CameraOnFrame extends StatefulWidget {
  const CameraOnFrame({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<CameraOnFrame> createState() => _CameraOnFrameState();
}

class _CameraOnFrameState extends State<CameraOnFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final width = 7 + _controller.value * 5;
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00D36A), width: width),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
