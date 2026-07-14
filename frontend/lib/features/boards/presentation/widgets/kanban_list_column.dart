import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../cards/data/card_models.dart';
import '../../application/board_detail_controller.dart';
import '../../application/position_calculator.dart';
import '../../data/board_models.dart';
import 'card_drop_gap.dart';
import 'kanban_card_tile.dart';

class KanbanListColumn extends ConsumerStatefulWidget {
  const KanbanListColumn({
    super.key,
    required this.arg,
    required this.list,
    required this.onCardTap,
  });

  final BoardDetailArg arg;
  final ListWithCards list;
  final void Function(CardModel card) onCardTap;

  @override
  ConsumerState<KanbanListColumn> createState() => _KanbanListColumnState();
}

class _KanbanListColumnState extends ConsumerState<KanbanListColumn> {
  bool _isAddingCard = false;
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleDrop(CardModel draggedCard, int insertIndex) {
    final cards = widget.list.cards;
    final draggedIndex = cards.indexWhere((c) => c.id == draggedCard.id);

    final filteredPositions = <double>[
      for (final c in cards)
        if (c.id != draggedCard.id) c.position,
    ];
    var filteredInsertIndex = insertIndex;
    if (draggedIndex != -1 && draggedIndex < insertIndex) {
      filteredInsertIndex -= 1;
    }
    final newPosition = PositionCalculator.calculate(filteredPositions, filteredInsertIndex);

    ref
        .read(boardDetailControllerProvider(widget.arg).notifier)
        .moveCard(
          cardId: draggedCard.id,
          fromListId: draggedCard.listId,
          toListId: widget.list.id,
          newPosition: newPosition,
        )
        .catchError((e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'common.unknownError'.tr();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  Future<void> _submitNewCard() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _isAddingCard = false);
      return;
    }
    _titleController.clear();
    try {
      await ref
          .read(boardDetailControllerProvider(widget.arg).notifier)
          .createCard(listId: widget.list.id, title: title);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'common.unknownError'.tr();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _confirmDeleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.list.title),
        content: Text('board.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(boardDetailControllerProvider(widget.arg).notifier)
          .deleteList(widget.list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.list.cards;

    final children = <Widget>[
      CardDropGap(onCardDropped: (card) => _handleDrop(card, 0)),
    ];
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: KanbanCardTile(
            card: card,
            workspaceId: widget.arg.workspaceId,
            onTap: () => widget.onCardTap(card),
          ),
        ),
      );
      children.add(
        CardDropGap(onCardDropped: (draggedCard) => _handleDrop(draggedCard, i + 1)),
      );
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.ink200),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.list.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.ink900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ink100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.ink500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 18),
                  color: AppColors.ink300,
                  onPressed: _confirmDeleteList,
                  tooltip: 'common.delete'.tr(),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(children: children),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: _isAddingCard
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        autofocus: true,
                        decoration: InputDecoration(hintText: 'card.titleLabel'.tr()),
                        onSubmitted: (_) => _submitNewCard(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: _submitNewCard,
                            child: Text('common.add'.tr()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _isAddingCard = false),
                          ),
                        ],
                      ),
                    ],
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => setState(() => _isAddingCard = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.add, size: 18, color: AppColors.ink500),
                            const SizedBox(width: 6),
                            Text(
                              'card.addCard'.tr(),
                              style: const TextStyle(
                                color: AppColors.ink500,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
