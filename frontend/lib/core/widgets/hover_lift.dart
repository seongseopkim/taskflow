import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 웹/데스크톱에서 마우스를 올리면 살짝 떠오르고 그림자가 깊어지는 카드 래퍼.
/// 정적인 화면이 "반응하지 않는다"는 인상을 주지 않도록 하는 최소한의 인터랙션.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.borderRadius,
    this.restShadow,
    this.hoverShadow,
    this.liftPixels = 2,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? restShadow;
  final List<BoxShadow>? hoverShadow;
  final double liftPixels;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -widget.liftPixels : 0, 0),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
          boxShadow: _hovering
              ? (widget.hoverShadow ?? AppShadows.hover)
              : (widget.restShadow ?? AppShadows.card),
        ),
        child: widget.child,
      ),
    );
  }
}
