import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 로그인/회원가입 화면용 배경 — 은은한 그라데이션 + 흐린 색 원 두 개로
/// 밋밋한 단색 배경 대신 약간의 "히어로" 느낌을 준다.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink50, Color(0xFFEEF2FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _blob(320, AppColors.primary.withValues(alpha: 0.16)),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _blob(360, const Color(0xFF14B8A6).withValues(alpha: 0.12)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
