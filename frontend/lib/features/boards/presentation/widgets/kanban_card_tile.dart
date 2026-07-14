import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/hover_lift.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../cards/data/card_models.dart';
import '../../../workspaces/application/workspace_members_provider.dart';

class KanbanCardTile extends ConsumerWidget {
  const KanbanCardTile({
    super.key,
    required this.card,
    required this.workspaceId,
    required this.onTap,
  });

  final CardModel card;
  final int workspaceId;
  final VoidCallback onTap;

  Widget _buildCard(BuildContext context, {String? assigneeName, bool dragging = false}) {
    final dueDate = card.dueDate;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.ink200),
          boxShadow: dragging ? AppShadows.dragging : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink900,
                    height: 1.35,
                  ),
                ),
                if (dueDate != null || assigneeName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOverdue ? AppColors.dangerSoft : AppColors.ink100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: isOverdue ? AppColors.danger : AppColors.ink500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MM/dd').format(dueDate),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isOverdue ? AppColors.danger : AppColors.ink500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      if (assigneeName != null)
                        Tooltip(
                          message: assigneeName,
                          child: UserAvatar(name: assigneeName, size: 22),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? assigneeName;
    if (card.assigneeId != null) {
      final members = ref.watch(workspaceMembersProvider(workspaceId)).value;
      final match = members?.where((m) => m.userId == card.assigneeId);
      if (match != null && match.isNotEmpty) assigneeName = match.first.name;
    }

    return Draggable<CardModel>(
      data: card,
      feedback: SizedBox(
        width: 256,
        child: _buildCard(context, assigneeName: assigneeName, dragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildCard(context, assigneeName: assigneeName),
      ),
      child: HoverLift(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: _buildCard(context, assigneeName: assigneeName),
      ),
    );
  }
}
