import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/projects_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/status_chip.dart';

class ReportReviewScreen extends ConsumerStatefulWidget {
  const ReportReviewScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends ConsumerState<ReportReviewScreen> {
  ReportModel? _report;
  bool _loading = true;
  bool _busy = false;
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
    setState(() => _busy = true);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final feedback = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(context).reject),
        content: TextField(
          controller: feedback,
          decoration: const InputDecoration(labelText: 'Feedback for valuer'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || feedback.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiServiceProvider).rejectReport(widget.projectId, feedback.text.trim());
      setState(() => _report = r);
      ref.invalidate(projectsProvider);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await ref.read(apiServiceProvider).downloadReportPdf(widget.projectId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/valuation_${widget.projectId}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Valuation report');
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailReport() async {
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email report'),
        content: TextField(
          controller: email,
          decoration: const InputDecoration(labelText: 'Recipient email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || email.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiServiceProvider).emailReport(widget.projectId, email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email sent')));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
              if (r.notes?.isNotEmpty == true)
                AppCard(
                  child: Text(r.notes!, style: Theme.of(context).textTheme.bodyMedium),
                ),
              if (r.lineItems.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...r.lineItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(child: Text(item.materialName)),
                          Text(fmt.format(item.total)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _sharePdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _emailReport,
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Email'),
                    ),
                  ),
                ],
              ),
              if (r.status == 'Submitted') ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _busy ? null : _approve,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(AppStrings.of(context).approve),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  icon: const Icon(Icons.undo_outlined),
                  label: Text(AppStrings.of(context).reject),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
