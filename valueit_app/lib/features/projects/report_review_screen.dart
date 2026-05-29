import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/status_chip.dart';
import 'manager_home.dart';

class ReportReviewScreen extends ConsumerStatefulWidget {
  const ReportReviewScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends ConsumerState<ReportReviewScreen> {
  ReportModel? _report;
  bool _loading = true;
  bool _approving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ref.read(apiServiceProvider).getReport(widget.projectId);
      setState(() {
        _report = r;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.statusCode == 404 ? 'No report submitted yet' : apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _approve() async {
    setState(() => _approving = true);
    try {
      await ref.read(apiServiceProvider).approveReport(widget.projectId);
      ref.invalidate(projectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valuation report approved')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Valuation report')),
      body: _loading
          ? const LoadingState(message: 'Loading report…')
          : _error != null
              ? EmptyState(icon: Icons.description_outlined, title: _error!)
              : _buildReport(context),
    );
  }

  Widget _buildReport(BuildContext context) {
    final r = _report!;
    final fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(label: r.status, tone: ProjectStatusTone.neutral),
                        const Spacer(),
                        Text(
                          fmt.format(r.calculatedValue ?? 0),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.brand),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Calculated property value', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Text(
                  r.reportContent ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                ),
              ),
              if (r.status == 'Submitted') ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _approving ? null : _approve,
                  icon: _approving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Approve & complete project'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
