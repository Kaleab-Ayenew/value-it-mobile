import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import 'models.dart';

class ProjectFilters {
  const ProjectFilters({this.query, this.status, this.includeArchived = false});

  final String? query;
  final String? status;
  final bool includeArchived;

  ProjectFilters copyWith({String? query, String? status, bool? includeArchived}) {
    return ProjectFilters(
      query: query ?? this.query,
      status: status ?? this.status,
      includeArchived: includeArchived ?? this.includeArchived,
    );
  }
}

final projectFiltersProvider = StateProvider<ProjectFilters>((_) => const ProjectFilters());

final projectsProvider = FutureProvider.autoDispose<List<ProjectModel>>((ref) {
  final f = ref.watch(projectFiltersProvider);
  return ref.watch(apiServiceProvider).projects(
        q: f.query?.trim().isEmpty == true ? null : f.query,
        status: f.status,
        includeArchived: f.includeArchived,
      );
});

final projectDetailProvider =
    FutureProvider.autoDispose.family<ProjectDetailModel, int>((ref, id) {
  return ref.watch(apiServiceProvider).projectDetail(id);
});

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) {
  return ref.watch(apiServiceProvider).notifications();
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => n.status == 'Unread').length,
    orElse: () => 0,
  );
});
