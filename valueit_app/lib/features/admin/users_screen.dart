import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/status_chip.dart';

final allUsersProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(apiServiceProvider).users();
});

class UsersAdminScreen extends ConsumerWidget {
  const UsersAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allUsersProvider);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(allUsersProvider),
      ),
      data: (users) => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length,
        itemBuilder: (_, i) => _UserTile(user: users[i], onChanged: () => ref.invalidate(allUsersProvider)),
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  const _UserTile({required this.user, required this.onChanged});

  final UserModel user;
  final VoidCallback onChanged;

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _busy = false;

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiServiceProvider).updateUserStatus(widget.user.userId, status);
      widget.onChanged();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.fullName, style: Theme.of(context).textTheme.titleMedium),
                  Text('${u.role} · ${u.email}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            StatusChip(label: u.accountStatus),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              PopupMenuButton<String>(
                onSelected: _setStatus,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'Active', child: Text('Set active')),
                  PopupMenuItem(value: 'Suspended', child: Text('Suspend')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
