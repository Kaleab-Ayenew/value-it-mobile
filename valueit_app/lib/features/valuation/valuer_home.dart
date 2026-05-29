import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/projects_provider.dart';
import '../../shared/widgets/notifications_button.dart';
import '../../shared/widgets/project_search_bar.dart';
import 'materials_screen.dart';

class ValuerHome extends ConsumerStatefulWidget {
  const ValuerHome({super.key});

  @override
  ConsumerState<ValuerHome> createState() => _ValuerHomeState();
}

class _ValuerHomeState extends ConsumerState<ValuerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _tab == 0 ? 'Valuation queue' : 'Material pricing',
      subtitle: _tab == 0
          ? 'Build cost-based reports from inspection data'
          : 'Reference prices for line-item calculations',
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      actions: const [NotificationsButton()],
      destinations: const [
        NavigationDestination(icon: Icon(Icons.calculate_outlined), label: 'Projects'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Materials'),
      ],
      body: _tab == 0 ? const _ProjectsTab() : const MaterialsScreen(),
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return async.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(projectsProvider),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return const EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No projects assigned',
            message: 'Wait for inspection data before preparing a valuation.',
          );
        }
        return RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async => ref.invalidate(projectsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              const ProjectSearchBar(),
              const PageHeader(
                title: 'Your projects',
                subtitle: 'Tap to review inspection and submit valuation',
              ),
              ...projects.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ProjectListCard(
                    title: p.projectName,
                    subtitle: p.location ?? '—',
                    status: p.status,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.request_quote_outlined, color: AppColors.accent, size: 22),
                    ),
                    onTap: () => context.push('/project/${p.projectId}?role=Valuer'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
