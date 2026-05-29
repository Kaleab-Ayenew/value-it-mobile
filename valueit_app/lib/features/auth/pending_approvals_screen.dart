import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

final pendingUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(apiServiceProvider).pendingUsers();
});

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingUsersProvider);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(pendingUsersProvider),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'No pending requests',
            message: 'New registration requests will appear here.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          itemBuilder: (_, i) {
            final u = users[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.brandLight,
                      child: Text(
                        u.fullName[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.fullName, style: Theme.of(context).textTheme.titleMedium),
                          Text('${u.email} · ${_roleLabel(u.role)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: () => _approve(ref, u.userId, true),
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                    ),
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: () => _approve(ref, u.userId, false),
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'SiteInspector' => 'Site Inspector',
      _ => role,
    };
  }

  Future<void> _approve(WidgetRef ref, int id, bool approved) async {
    await ref.read(apiServiceProvider).approveUser(id, approved);
    ref.invalidate(pendingUsersProvider);
  }
}
