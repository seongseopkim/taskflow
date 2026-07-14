import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 이름/이메일 기반 이니셜 아바타. id를 시드로 팔레트에서 색을 결정론적으로 고른다.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.seed,
    this.size = 24,
  });

  final String name;
  final int? seed;
  final double size;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  Color get _color {
    final key = seed ?? name.hashCode;
    final index = key.abs() % AppColors.avatarPalette.length;
    return AppColors.avatarPalette[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
