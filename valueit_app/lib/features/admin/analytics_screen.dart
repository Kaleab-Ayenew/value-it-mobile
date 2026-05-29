import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../shared/api_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

final _analyticsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(apiServiceProvider).analyticsOverview();
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_analyticsProvider);
    final s = AppStrings.of(context);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(_analyticsProvider),
      ),
      data: (a) => ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          PageHeader(title: s.analytics, subtitle: 'Portfolio overview'),
          _StatGrid([
            _Stat('Total projects', '${a.totalProjects}', Icons.folder_copy_outlined),
            _Stat('Pending', '${a.pending}', Icons.hourglass_empty),
            _Stat('In progress', '${a.inProgress}', Icons.sync),
            _Stat('Completed', '${a.completed}', Icons.check_circle_outline),
            _Stat('Pending approvals', '${a.pendingApprovals}', Icons.how_to_reg_outlined),
            _Stat('Reports to review', '${a.pendingReports}', Icons.description_outlined),
            _Stat('Active valuers', '${a.activeValuers}', Icons.person_outline),
            _Stat('Active inspectors', '${a.activeInspectors}', Icons.engineering_outlined),
          ]),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid(this.stats);
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: stats
          .map(
            (s) => SizedBox(
              width: 160,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.icon, color: AppColors.brand, size: 22),
                    const SizedBox(height: AppSpacing.sm),
                    Text(s.value, style: Theme.of(context).textTheme.headlineSmall),
                    Text(s.label, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
