import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 페이지 스택에 쌓여있으면 pop, 아니면(새로고침/직접 URL 진입 등으로
/// 스택이 비어있으면) fallbackPath로 이동 — 어떤 상황에서도 항상 동작하는 뒤로가기.
class BackLeadingButton extends StatelessWidget {
  const BackLeadingButton({super.key, required this.fallbackPath});

  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackPath);
        }
      },
    );
  }
}
