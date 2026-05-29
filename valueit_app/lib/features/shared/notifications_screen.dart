import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/projects_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(s.notifications),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(apiServiceProvider).markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
            },
            child: Text(s.markAllRead),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e is DioException ? apiErrorMessage(e) : '$e',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'No notifications',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: items.length,
              itemBuilder: (_, i) => _NotificationTile(n: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.n});

  final NotificationModel n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat.MMMd().add_jm();
    final unread = n.status == 'Unread';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () async {
          if (unread) {
            await ref.read(apiServiceProvider).markNotificationRead(n.notificationId);
            ref.invalidate(notificationsProvider);
          }
          if (n.entityType == 'Project' && n.entityId != null && context.mounted) {
            context.push('/project/${n.entityId}');
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              unread ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined,
              color: unread ? AppColors.brand : AppColors.inkSubtle,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(n.message, style: Theme.of(context).textTheme.bodySmall),
                  if (n.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(fmt.format(n.createdAt!), style: Theme.of(context).textTheme.labelSmall),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
