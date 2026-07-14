import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_leading_button.dart';
import '../../../core/widgets/common_app_bar_actions.dart';
import '../../cards/presentation/card_detail_dialog.dart';
import '../application/board_detail_controller.dart';
import 'widgets/kanban_list_column.dart';

class BoardDetailPage extends ConsumerStatefulWidget {
  const BoardDetailPage({super.key, required this.workspaceId, required this.boardId});

  final int workspaceId;
  final int boardId;

  @override
  ConsumerState<BoardDetailPage> createState() => _BoardDetailPageState();
}

class _BoardDetailPageState extends ConsumerState<BoardDetailPage> {
  bool _isAddingList = false;
  final _listTitleController = TextEditingController();

  BoardDetailArg get _arg => (workspaceId: widget.workspaceId, boardId: widget.boardId);

  @override
  void dispose() {
    _listTitleController.dispose();
    super.dispose();
  }

  Future<void> _submitNewList() async {
    final title = _listTitleController.text.trim();
    if (title.isEmpty) {
      setState(() => _isAddingList = false);
      return;
    }
    _listTitleController.clear();
    try {
      await ref.read(boardDetailControllerProvider(_arg).notifier).createList(title);
    } catch (e) {
      if (mounted) {
        final message = e is ApiException ? e.message : 'common.unknownError'.tr();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardDetailControllerProvider(_arg));

    return Scaffold(
      backgroundColor: AppColors.ink100,
      appBar: AppBar(
        leading: BackLeadingButton(fallbackPath: '/workspaces/${widget.workspaceId}/boards'),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.boardColor(widget.boardId),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              boardAsync.value?.name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: const [CommonAppBarActions(), SizedBox(width: 8)],
      ),
      body: boardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'common.unknownError'.tr()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(boardDetailControllerProvider(_arg).notifier).refresh(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (board) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final list in board.lists)
                  KanbanListColumn(
                    arg: _arg,
                    list: list,
                    onCardTap: (card) => showCardDetailDialog(
                      context: context,
                      arg: _arg,
                      card: card,
                      boardId: widget.boardId,
                    ),
                  ),
                SizedBox(
                  width: 272,
                  child: _isAddingList
                      ? Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.ink200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _listTitleController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'board.listTitleLabel'.tr(),
                                ),
                                onSubmitted: (_) => _submitNewList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: _submitNewList,
                                    child: Text('common.add'.tr()),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(() => _isAddingList = false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => setState(() => _isAddingList = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.ink300, style: BorderStyle.solid),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add, size: 18, color: AppColors.ink500),
                                  const SizedBox(width: 8),
                                  Text(
                                    'board.addList'.tr(),
                                    style: const TextStyle(
                                      color: AppColors.ink500,
                                      fontWeight: FontWeight.w600,
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
        },
      ),
    );
  }
}
