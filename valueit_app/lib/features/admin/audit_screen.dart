import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

final auditProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(apiServiceProvider).auditLogs();
});

class AuditScreen extends ConsumerWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditProvider);
    final fmt = DateFormat.yMMMd().add_jm();

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(auditProvider),
      ),
      data: (logs) => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: logs.length,
        itemBuilder: (_, i) {
          final l = logs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l.action} · ${l.entityType}', style: Theme.of(context).textTheme.titleSmall),
                  if (l.detail != null) Text(l.detail!, style: Theme.of(context).textTheme.bodySmall),
                  if (l.createdAt != null)
                    Text(fmt.format(l.createdAt!), style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
