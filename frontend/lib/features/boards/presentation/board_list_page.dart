import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/back_leading_button.dart';
import '../../../core/widgets/common_app_bar_actions.dart';
import '../../../core/widgets/hover_lift.dart';
import '../application/board_list_controller.dart';
import '../data/board_models.dart';

class BoardListPage extends ConsumerWidget {
  const BoardListPage({super.key, required this.workspaceId});

  final int workspaceId;

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('board.createTitle'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'board.nameLabel'.tr()),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text('common.create'.tr()),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      try {
        await ref
            .read(boardListControllerProvider(workspaceId).notifier)
            .createBoard(name.trim());
      } catch (e) {
        if (context.mounted) {
          final message = e is ApiException ? e.message : 'common.unknownError'.tr();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Board board) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(board.name),
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
      try {
        await ref
            .read(boardListControllerProvider(workspaceId).notifier)
            .deleteBoard(board.id);
      } catch (e) {
        if (context.mounted) {
          final message = e is ApiException ? e.message : 'common.unknownError'.tr();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardsAsync = ref.watch(boardListControllerProvider(workspaceId));

    return Scaffold(
      appBar: AppBar(
        leading: const BackLeadingButton(fallbackPath: '/'),
        title: Text('board.title'.tr()),
        actions: const [CommonAppBarActions(), SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('board.create'.tr()),
      ),
      body: boardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'common.unknownError'.tr()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(boardListControllerProvider(workspaceId).notifier).refresh(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (boards) {
          if (boards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('board.empty'.tr(), style: const TextStyle(color: AppColors.ink500)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(boardListControllerProvider(workspaceId).notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 236,
                childAspectRatio: 1.5,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: boards.length,
              itemBuilder: (context, index) {
                final board = boards[index];
                final color = AppColors.boardColor(board.id);
                return HoverLift(
                  liftPixels: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, Color.lerp(color, Colors.black, 0.22)!],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => context.push('/workspaces/$workspaceId/boards/${board.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.dashboard_outlined, color: Colors.white70, size: 18),
                              const Spacer(),
                              Expanded(
                                child: Text(
                                  board.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _confirmDelete(context, ref, board),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
