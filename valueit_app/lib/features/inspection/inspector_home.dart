import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../projects/manager_home.dart';

class InspectorHome extends ConsumerWidget {
  const InspectorHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return AppShell(
      title: 'Site inspections',
      subtitle: 'Assigned valuation projects awaiting field data',
      selectedIndex: 0,
      onSelect: (_) {},
      destinations: const [
        NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Assignments'),
      ],
      body: async.when(
        loading: () => const LoadingState(message: 'Loading assignments…'),
        error: (e, _) => ErrorState(
          message: e is DioException ? apiErrorMessage(e) : '$e',
          onRetry: () => ref.invalidate(projectsProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const EmptyState(
              icon: Icons.location_off_outlined,
              title: 'No assignments',
              message: 'Your manager will assign projects when ready.',
            );
          }
          return RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PageHeader(
                  title: '${projects.length} assignments',
                  subtitle: 'Open a project to submit inspection data and photos',
                ),
                ...projects.map(
                  (p) => ProjectListCard(
                    title: p.projectName,
                    subtitle: p.location ?? 'Location TBD',
                    status: p.status,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: AppColors.info, size: 22),
                    ),
                    onTap: () => context.push('/inspector/project/${p.projectId}'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
