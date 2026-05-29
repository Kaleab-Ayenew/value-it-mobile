import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../shared/models.dart';
import '../../shared/projects_provider.dart';
import '../../shared/shell.dart';
import '../../shared/widgets/action_sheet.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/notifications_button.dart';
import '../../shared/widgets/project_search_bar.dart';
import '../admin/analytics_screen.dart';
import '../admin/audit_screen.dart';
import '../admin/clients_screen.dart';
import '../admin/materials_admin_screen.dart';
import '../admin/users_screen.dart';
import '../auth/pending_approvals_screen.dart';

class ManagerHome extends ConsumerStatefulWidget {
  const ManagerHome({super.key});

  @override
  ConsumerState<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends ConsumerState<ManagerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final titles = ['Valuation projects', 'User approvals', s.analytics, 'Administration'];
    final subtitles = [
      'Create, assign, and track cost-based valuations',
      'Review pending registrations',
      'Portfolio metrics and activity',
      'Clients, users, materials, and audit',
    ];

    return AppShell(
      title: titles[_tab],
      subtitle: subtitles[_tab],
      selectedIndex: _tab,
      onSelect: (i) => setState(() => _tab = i),
      actions: const [NotificationsButton(), _LocaleToggle()],
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
      destinations: [
        NavigationDestination(icon: const Icon(Icons.folder_copy_outlined), label: s.projects),
        const NavigationDestination(icon: Icon(Icons.how_to_reg_outlined), label: 'Approvals'),
        NavigationDestination(icon: const Icon(Icons.insights_outlined), label: s.analytics),
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), label: 'Admin'),
      ],
      body: switch (_tab) {
        0 => const _ProjectsTab(),
        1 => const PendingApprovalsScreen(),
        2 => const AnalyticsScreen(),
        3 => const _AdminHub(),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _LocaleToggle extends ConsumerWidget {
  const _LocaleToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return IconButton(
      tooltip: 'Language',
      onPressed: () {
        ref.read(localeProvider.notifier).state =
            locale.languageCode == 'en' ? const Locale('am') : const Locale('en');
      },
      icon: Text(locale.languageCode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _AdminHub extends StatelessWidget {
  const _AdminHub();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final items = [
      (s.clients, Icons.people_outline, const ClientsScreen()),
      (s.users, Icons.group_outlined, const UsersAdminScreen()),
      (s.materials, Icons.inventory_2_outlined, const MaterialsAdminScreen()),
      (s.auditLog, Icons.history, const AuditScreen()),
    ];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => e.$3)),
                child: ListTile(
                  leading: Icon(e.$2, color: AppColors.brand),
                  title: Text(e.$1),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
          )
          .toList(),
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
          return Column(
            children: [
              const ProjectSearchBar(),
              Expanded(
                child: EmptyState(
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
                ),
              ),
            ],
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
                title: 'Projects',
                subtitle: 'Tap for detail, assign team, or review reports',
              ),
              ...projects.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: ProjectListCard(
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
                      onTap: () => _showActions(context, ref, p),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, ProjectModel project) {
    AppActionSheet.show(
      context,
      title: project.projectName,
      actions: [
        AppSheetAction(
          icon: Icons.info_outline,
          label: 'Project detail',
          onTap: () => context.push('/project/${project.projectId}?role=Manager'),
        ),
        AppSheetAction(
          icon: Icons.group_outlined,
          label: 'Assign team',
          subtitle: 'Valuer and site inspector',
          onTap: () => context.push('/manager/project/${project.projectId}/assign'),
        ),
        AppSheetAction(
          icon: Icons.description_outlined,
          label: 'Review report',
          onTap: () => context.push('/manager/project/${project.projectId}/report'),
        ),
      ],
    );
  }
}
