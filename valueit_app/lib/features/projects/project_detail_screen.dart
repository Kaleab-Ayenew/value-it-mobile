import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../core/design_tokens.dart';
import '../../shared/projects_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/status_chip.dart';
import 'project_chat_screen.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId, this.role = 'Manager'});

  final int projectId;
  final String role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectDetailProvider(projectId));
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Project detail')),
      body: async.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e is DioException ? apiErrorMessage(e) : '$e',
          onRetry: () => ref.invalidate(projectDetailProvider(projectId)),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.projectName, style: Theme.of(context).textTheme.headlineSmall),
                      ),
                      StatusChip(label: p.status, tone: statusTone(p.status)),
                    ],
                  ),
                  if (p.location != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(p.location!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  if (p.client != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text('Client: ${p.client!.fullName}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Team', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Valuer: ${p.valuerName ?? '—'}'),
                  Text('Inspector: ${p.inspectorName ?? '—'}'),
                  if (p.hasReport) Text('Report: ${p.reportStatus ?? '—'}'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...p.timeline.map((e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.circle, size: 8, color: AppColors.brand),
                  title: Text(e.label),
                  subtitle: e.at != null ? Text(DateFormat.yMMMd().format(e.at!)) : null,
                )),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProjectChatScreen(projectId: projectId),
                ),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: Text(s.chat),
            ),
            if (role == 'Manager') ...[
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => context.push('/manager/project/$projectId/assign'),
                icon: const Icon(Icons.group_outlined),
                label: const Text('Assign team'),
              ),
              if (p.hasReport)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push('/manager/project/$projectId/report'),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Review report'),
                  ),
                ),
            ],
            if (role == 'Valuer')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: FilledButton.icon(
                  onPressed: () => context.push('/valuer/project/$projectId'),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Open valuation'),
                ),
              ),
            if (role == 'SiteInspector')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: FilledButton.icon(
                  onPressed: () => context.push('/inspector/project/$projectId'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Site inspection'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
