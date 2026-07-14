import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/application/auth_controller.dart';
import '../../boards/application/board_detail_controller.dart';
import '../../comments/application/comment_controller.dart';
import '../../labels/application/label_controller.dart';
import '../../workspaces/application/workspace_members_provider.dart';
import '../data/card_api.dart';
import '../data/card_models.dart';

Future<void> showCardDetailDialog({
  required BuildContext context,
  required BoardDetailArg arg,
  required CardModel card,
  required int boardId,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: CardDetailDialog(arg: arg, card: card, boardId: boardId),
      ),
    ),
  );
}

class CardDetailDialog extends ConsumerStatefulWidget {
  const CardDetailDialog({
    super.key,
    required this.arg,
    required this.card,
    required this.boardId,
  });

  final BoardDetailArg arg;
  final CardModel card;
  final int boardId;

  @override
  ConsumerState<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends ConsumerState<CardDetailDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _commentController;
  int? _assigneeId;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.card.title);
    _descriptionController = TextEditingController(text: widget.card.description ?? '');
    _commentController = TextEditingController();
    _assigneeId = widget.card.assigneeId;
    _dueDate = widget.card.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _showError(Object e) {
    final message = e is ApiException ? e.message : 'common.unknownError'.tr();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(cardApiProvider).updateCard(
            cardId: widget.card.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text,
            assigneeId: _assigneeId,
            dueDate: _dueDate,
          );
      await ref.read(boardDetailControllerProvider(widget.arg).notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('card.deleteConfirm'.tr()),
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
    if (confirmed != true) return;
    try {
      await ref.read(cardApiProvider).deleteCard(widget.card.id);
      await ref.read(boardDetailControllerProvider(widget.arg).notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.ink200)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.credit_card_outlined, size: 17, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'card.detailTitle'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.ink500,
                onPressed: _delete,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.ink500,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(labelText: 'card.titleLabel'.tr()),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'card.descriptionLabel'.tr()),
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _AssigneeDropdown(
                        workspaceId: widget.arg.workspaceId,
                        value: _assigneeId,
                        onChanged: (value) => setState(() => _assigneeId = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _DueDateField(dueDate: _dueDate, onPick: _pickDueDate, onClear: () => setState(() => _dueDate = null))),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('common.save'.tr()),
                  ),
                ),
                const Divider(height: 40),
                _LabelSection(boardId: widget.boardId, cardId: widget.card.id),
                const Divider(height: 40),
                _CommentSection(
                  cardId: widget.card.id,
                  workspaceId: widget.arg.workspaceId,
                  commentController: _commentController,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.ink500),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink900),
        ),
      ],
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({required this.dueDate, required this.onPick, required this.onClear});

  final DateTime? dueDate;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'card.dueDateLabel'.tr(),
        suffixIcon: dueDate != null
            ? IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onClear,
              )
            : null,
      ),
      child: InkWell(
        onTap: onPick,
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: dueDate != null ? AppColors.ink700 : AppColors.ink300,
            ),
            const SizedBox(width: 8),
            Text(
              dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate!) : 'card.noDueDate'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: dueDate != null ? AppColors.ink900 : AppColors.ink300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeDropdown extends ConsumerWidget {
  const _AssigneeDropdown({
    required this.workspaceId,
    required this.value,
    required this.onChanged,
  });

  final int workspaceId;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));

    return membersAsync.when(
      loading: () => InputDecorator(
        decoration: InputDecoration(labelText: 'card.assigneeLabel'.tr()),
        child: const SizedBox(height: 20, child: LinearProgressIndicator()),
      ),
      error: (e, st) => InputDecorator(
        decoration: InputDecoration(labelText: 'card.assigneeLabel'.tr()),
        child: Text(e is ApiException ? e.message : 'common.unknownError'.tr()),
      ),
      data: (members) {
        final validValue = members.any((m) => m.userId == value) ? value : null;
        return DropdownButtonFormField<int?>(
          initialValue: validValue,
          decoration: InputDecoration(labelText: 'card.assigneeLabel'.tr()),
          items: [
            DropdownMenuItem<int?>(value: null, child: Text('card.noAssignee'.tr())),
            for (final member in members)
              DropdownMenuItem<int?>(value: member.userId, child: Text(member.name)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _LabelSection extends ConsumerWidget {
  const _LabelSection({required this.boardId, required this.cardId});

  final int boardId;
  final int cardId;

  Future<void> _createLabelDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#0C66E4');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('label.create'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'label.nameLabel'.tr()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: colorController,
              decoration: InputDecoration(labelText: 'label.colorLabel'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.create'.tr()),
          ),
        ],
      ),
    );
    if (result == true && nameController.text.trim().isNotEmpty) {
      try {
        await ref
            .read(labelControllerProvider(boardId).notifier)
            .createLabel(name: nameController.text.trim(), color: colorController.text.trim());
      } catch (e) {
        if (context.mounted) {
          final message = e is ApiException ? e.message : 'common.unknownError'.tr();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    }
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelsAsync = ref.watch(labelControllerProvider(boardId));
    final attached = ref.watch(cardLabelStateProvider(cardId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(icon: Icons.label_outline, label: 'label.title'.tr()),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _createLabelDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: Text('label.create'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        labelsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => Text(e is ApiException ? e.message : 'common.unknownError'.tr()),
          data: (labels) {
            if (labels.isEmpty) return Text('label.empty'.tr());
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in labels)
                  FilterChip(
                    label: Text(label.name),
                    selected: attached.contains(label.id),
                    backgroundColor: _parseColor(label.color).withValues(alpha: 0.25),
                    selectedColor: _parseColor(label.color).withValues(alpha: 0.6),
                    onSelected: (selected) async {
                      final notifier = ref.read(cardLabelStateProvider(cardId).notifier);
                      try {
                        if (selected) {
                          await notifier.attach(label.id);
                        } else {
                          await notifier.detach(label.id);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          final message =
                              e is ApiException ? e.message : 'common.unknownError'.tr();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentSection extends ConsumerWidget {
  const _CommentSection({
    required this.cardId,
    required this.workspaceId,
    required this.commentController,
  });

  final int cardId;
  final int workspaceId;
  final TextEditingController commentController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentControllerProvider(cardId));
    final myUserId = ref.watch(authControllerProvider).value?.id;
    final members = ref.watch(workspaceMembersProvider(workspaceId)).value;

    String nameFor(int userId) {
      final match = members?.where((m) => m.userId == userId);
      if (match != null && match.isNotEmpty) return match.first.name;
      return '#$userId';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.chat_bubble_outline, label: 'comment.title'.tr()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: commentController,
                decoration: InputDecoration(hintText: 'comment.placeholder'.tr()),
                onSubmitted: (_) async {
                  final text = commentController.text.trim();
                  if (text.isEmpty) return;
                  commentController.clear();
                  await ref.read(commentControllerProvider(cardId).notifier).addComment(text);
                },
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final text = commentController.text.trim();
                if (text.isEmpty) return;
                commentController.clear();
                await ref.read(commentControllerProvider(cardId).notifier).addComment(text);
              },
              child: Text('comment.send'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => Text(e is ApiException ? e.message : 'common.unknownError'.tr()),
          data: (comments) {
            if (comments.isEmpty) return Text('comment.empty'.tr());
            return Column(
              children: [
                for (final comment in comments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(name: nameFor(comment.userId), seed: comment.userId, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.ink50,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.ink200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        nameFor(comment.userId),
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MM/dd HH:mm').format(comment.createdAt),
                                      style: const TextStyle(fontSize: 11, color: AppColors.ink300),
                                    ),
                                    if (comment.userId == myUserId)
                                      InkWell(
                                        onTap: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              content: Text('comment.deleteConfirm'.tr()),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: Text('common.cancel'.tr()),
                                                ),
                                                FilledButton(
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: AppColors.danger,
                                                  ),
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: Text('common.delete'.tr()),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            await ref
                                                .read(commentControllerProvider(cardId).notifier)
                                                .deleteComment(comment.id);
                                          }
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(Icons.delete_outline, size: 15, color: AppColors.ink300),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(fontSize: 13.5, color: AppColors.ink700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
