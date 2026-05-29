import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import 'manager_home.dart';

final _usersProvider = FutureProvider.autoDispose.family<List<UserModel>, String>((ref, role) {
  return ref.watch(apiServiceProvider).users(role: role, status: 'Active');
});

class AssignScreen extends ConsumerStatefulWidget {
  const AssignScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends ConsumerState<AssignScreen> {
  int? _valuerId;
  int? _inspectorId;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final valuers = ref.watch(_usersProvider('Valuer'));
    final inspectors = ref.watch(_usersProvider('SiteInspector'));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Assign team')),
      body: valuers.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
        data: (valuerList) => inspectors.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: '$e'),
          data: (inspectorList) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: AppColors.info),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Both roles must be assigned before field work begins.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FormSection(
                      title: 'Team members',
                      children: [
                        DropdownButtonFormField<int?>(
                          initialValue: _valuerId,
                          decoration: const InputDecoration(labelText: 'Valuer'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Select valuer')),
                            ...valuerList.map(
                              (u) => DropdownMenuItem(value: u.userId, child: Text(u.fullName)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _valuerId = v),
                        ),
                        DropdownButtonFormField<int?>(
                          initialValue: _inspectorId,
                          decoration: const InputDecoration(labelText: 'Site inspector'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Select inspector')),
                            ...inspectorList.map(
                              (u) => DropdownMenuItem(value: u.userId, child: Text(u.fullName)),
                            ),
                          ],
                          onChanged: (v) => setState(() => _inspectorId = v),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      InlineErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save assignment'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_valuerId == null || _inspectorId == null) {
      setState(() => _error = 'Select both valuer and site inspector');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(apiServiceProvider).assignProject(
            widget.projectId,
            valuerId: _valuerId,
            inspectorId: _inspectorId,
          );
      ref.invalidate(projectsProvider);
      if (mounted) context.pop();
    } on DioException catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
