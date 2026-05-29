import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../../core/l10n.dart';
import '../../shared/projects_provider.dart';
import 'materials_screen.dart';

class ValuationScreen extends ConsumerStatefulWidget {
  const ValuationScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends ConsumerState<ValuationScreen> {
  InspectionModel? _inspection;
  final List<LineItem> _items = [];
  final _notes = TextEditingController();
  ReportModel? _existingReport;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final insp = await api.getInspection(widget.projectId);
      ReportModel? report;
      try {
        report = await api.getReport(widget.projectId);
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
      }
      setState(() {
        _inspection = insp;
        _existingReport = report;
        if (report != null) {
          _items
            ..clear()
            ..addAll(report.lineItems);
          _notes.text = report.notes ?? '';
        }
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.statusCode == 404
            ? 'Inspection not submitted yet'
            : apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _addLine(MaterialModel m) {
    setState(() {
      _items.add(LineItem(
        materialName: m.materialName,
        quantity: 1,
        unit: m.unit,
        unitPrice: m.unitPrice,
      ));
    });
  }

  double get _total => _items.fold(0.0, (s, i) => s + i.total);

  Future<void> _saveReport(String status) async {
    if (_items.isEmpty) {
      setState(() => _error = 'Add at least one line item');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiServiceProvider).submitReport(widget.projectId, {
        'line_items': _items.map((i) => i.toJson()).toList(),
        'notes': _notes.text.trim(),
        'status': status,
      });
      ref.invalidate(projectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'Draft' ? 'Draft saved' : 'Valuation report submitted'),
          ),
        );
        if (status == 'Submitted') context.pop();
      }
    } on DioException catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showMaterialPicker() async {
    final materials = await ref.read(materialsProvider.future);
    if (!mounted) return;
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);
    final m = await showModalBottomSheet<MaterialModel>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Add material', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: materials.length,
                itemBuilder: (_, i) {
                  final mat = materials[i];
                  return ListTile(
                    title: Text(mat.materialName),
                    subtitle: Text('Per ${mat.unit}'),
                    trailing: Text(
                      currency.format(mat.unitPrice),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brand),
                    ),
                    onTap: () => Navigator.pop(ctx, mat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (m != null) _addLine(m);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 2);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: LoadingState(message: 'Loading inspection data…'),
      );
    }
    if (_error != null && _inspection == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(title: const Text('Valuation worksheet')),
        body: EmptyState(icon: Icons.warning_amber_outlined, title: _error!),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Valuation worksheet'),
        actions: [
          TextButton.icon(
            onPressed: _showMaterialPicker,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add line'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormSection(
                  title: 'Inspection summary',
                  children: [
                    Text(_inspection!.observations ?? 'No observations recorded',
                        style: Theme.of(context).textTheme.bodyMedium),
                    if (_inspection!.measurements?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(_inspection!.measurements!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (_inspection!.photos.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _inspection!.photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: Image.network(
                              AppConfig.photoUrl(
                                filePath: _inspection!.photos[i].filePath,
                                url: _inspection!.photos[i].url,
                              ),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'LINE ITEMS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.inkSubtle,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    if (_items.isEmpty)
                      Text('No items yet', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ..._items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.materialName,
                                    style: Theme.of(context).textTheme.titleMedium),
                                Text(
                                  '${item.quantity} ${item.unit} × ${currency.format(item.unitPrice)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(item.total),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.brand,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.inkSubtle),
                            onPressed: () => setState(() => _items.removeAt(i)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                AppCard(
                  child: Row(
                    children: [
                      Text('Estimated value', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        currency.format(_total),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Valuer notes',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                if (_existingReport?.managerFeedback != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineErrorBanner(message: 'Manager feedback: ${_existingReport!.managerFeedback}'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineErrorBanner(message: _error!),
                ],
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _saveReport('Draft'),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(AppStrings.of(context).saveDraft),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _saveReport('Submitted'),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(AppStrings.of(context).submitReport),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
