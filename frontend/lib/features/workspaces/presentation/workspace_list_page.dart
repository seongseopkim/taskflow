import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_app_bar_actions.dart';
import '../../../core/widgets/hover_lift.dart';
import '../application/workspace_controller.dart';
import '../data/workspace_models.dart';

class WorkspaceListPage extends ConsumerWidget {
  const WorkspaceListPage({super.key});

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('workspace.createTitle'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: 'workspace.nameLabel'.tr()),
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
        await ref.read(workspaceControllerProvider.notifier).createWorkspace(name.trim());
      } catch (e) {
        if (context.mounted) {
          final message = e is ApiException ? e.message : 'common.unknownError'.tr();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Workspace ws) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ws.name),
        content: Text('workspace.deleteConfirm'.tr()),
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
        await ref.read(workspaceControllerProvider.notifier).deleteWorkspace(ws.id);
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
    final workspacesAsync = ref.watch(workspaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('workspace.title'.tr()),
        actions: const [CommonAppBarActions(), SizedBox(width: 8)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('workspace.create'.tr()),
      ),
      body: workspacesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'common.unknownError'.tr()),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(workspaceControllerProvider.notifier).refresh(),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (workspaces) {
          if (workspaces.isEmpty) {
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
                      Icons.workspaces_outline,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'workspace.empty'.tr(),
                    style: const TextStyle(color: AppColors.ink500),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(workspaceControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              itemCount: workspaces.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ws = workspaces[index];
                return HoverLift(
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => context.push('/workspaces/${ws.id}/boards'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.workspaces_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              ws.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink900,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: AppColors.ink300,
                            onPressed: () => _confirmDelete(context, ref, ws),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.ink300),
                        ],
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
