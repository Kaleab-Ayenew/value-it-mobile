import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../projects_provider.dart';

class ProjectSearchBar extends ConsumerWidget {
  const ProjectSearchBar({super.key, this.showStatusFilter = true});

  final bool showStatusFilter;

  static const _statuses = ['Pending', 'In Progress', 'Completed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(projectFiltersProvider);
    final s = AppStrings.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: s.searchHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (q) {
              ref.read(projectFiltersProvider.notifier).state =
                  filters.copyWith(query: q);
              ref.invalidate(projectsProvider);
            },
          ),
          if (showStatusFilter) ...[
            const SizedBox(height: AppSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filters.status == null,
                    onSelected: (_) {
                      ref.read(projectFiltersProvider.notifier).state =
                          filters.copyWith(status: null);
                      ref.invalidate(projectsProvider);
                    },
                  ),
                  ..._statuses.map(
                    (st) => Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: FilterChip(
                        label: Text(st),
                        selected: filters.status == st,
                        onSelected: (_) {
                          ref.read(projectFiltersProvider.notifier).state =
                              filters.copyWith(status: st);
                          ref.invalidate(projectsProvider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
