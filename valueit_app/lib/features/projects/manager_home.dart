import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/shell.dart';
import '../../shared/widgets/action_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../auth/pending_approvals_screen.dart';

final projectsProvider = FutureProvider.autoDispose<List<ProjectModel>>((ref) {
  return ref.watch(apiServiceProvider).projects();
});

class ManagerHome extends ConsumerStatefulWidget {
  const ManagerHome({super.key});

  @override
  ConsumerState<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends ConsumerState<ManagerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: _tab == 0 ? 'Valuation projects' : 'User approvals',
      subtitle: _tab == 0 ? 'Create, assign, and track cost-based valuations' : 'Review pending registrations',
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/manager/project/new');
                ref.invalidate(projectsProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('New project'),
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
            )
          : null,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.folder_copy_outlined), label: 'Projects'),
        NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Approvals'),
      ],
      body: _tab == 0 ? const _ProjectsTab() : const PendingApprovalsScreen(),
    );
  }
}

class _ProjectsTab extends ConsumerWidget {
  const _ProjectsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);

    return async.when(
      loading: () => const LoadingState(message: 'Loading projects…'),
      error: (e, _) => ErrorState(
        message: e is DioException ? apiErrorMessage(e) : '$e',
        onRetry: () => ref.invalidate(projectsProvider),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return EmptyState(
            icon: Icons.folder_open_outlined,
            title: 'No valuation projects',
            message: 'Create a project to assign valuers and site inspectors.',
            action: FilledButton.icon(
              onPressed: () async {
                await context.push('/manager/project/new');
                ref.invalidate(projectsProvider);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create project'),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async => ref.invalidate(projectsProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              PageHeader(
                title: '${projects.length} active projects',
                subtitle: 'Tap a project to assign team or review reports',
              ),
              ...projects.map((p) => ProjectListCard(
                    title: p.projectName,
                    subtitle: p.location ?? 'Location not set',
                    status: p.status,
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandLight,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(Icons.home_work_outlined, color: AppColors.brand, size: 22),
                    ),
                    onTap: () => _showActions(context, p),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showActions(BuildContext context, ProjectModel project) {
    AppActionSheet.show(
      context,
      title: project.projectName,
      actions: [
        AppSheetAction(
          icon: Icons.group_outlined,
          label: 'Assign team',
          subtitle: 'Valuer and site inspector',
          onTap: () => context.push('/manager/project/${project.projectId}/assign'),
        ),
        AppSheetAction(
          icon: Icons.description_outlined,
          label: 'Review report',
          subtitle: 'Approve submitted valuation',
          onTap: () => context.push('/manager/project/${project.projectId}/report'),
        ),
      ],
    );
  }
}
