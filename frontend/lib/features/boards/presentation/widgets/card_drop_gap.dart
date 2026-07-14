import 'package:flutter/material.dart';

import '../../../cards/data/card_models.dart';

/// 카드와 카드 사이의 "여기로 드롭하면 이 위치에 들어감"을 표현하는 좁은 영역.
class CardDropGap extends StatelessWidget {
  const CardDropGap({super.key, required this.onCardDropped});

  final void Function(CardModel card) onCardDropped;

  @override
  Widget build(BuildContext context) {
    return DragTarget<CardModel>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) => onCardDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: isHovering ? 40 : 8,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: isHovering ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(6),
            border: isHovering
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5)
                : null,
          ),
        );
      },
    );
  }
}
