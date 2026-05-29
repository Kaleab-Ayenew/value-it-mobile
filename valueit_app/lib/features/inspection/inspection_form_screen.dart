import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/design_tokens.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/photo_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';
import '../projects/manager_home.dart';

class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  final _observations = TextEditingController();
  final _measurements = TextEditingController();
  final _remarks = TextEditingController();
  DateTime _date = DateTime.now();
  InspectionModel? _existing;
  List<PickedPhoto> _pendingPhotos = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _observations.dispose();
    _measurements.dispose();
    _remarks.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final insp = await ref.read(apiServiceProvider).getInspection(widget.projectId);
      setState(() {
        _existing = insp;
        _observations.text = insp.observations ?? '';
        _measurements.text = insp.measurements ?? '';
        _remarks.text = insp.remarks ?? '';
        if (insp.inspectionDate != null) {
          _date = DateTime.tryParse(insp.inspectionDate!) ?? _date;
        }
        _loading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(() => _loading = false);
      } else {
        setState(() {
          _error = apiErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      InspectionModel insp;
      if (_existing == null) {
        insp = await api.submitInspection(widget.projectId, {
          'inspection_date': dateStr,
          'observations': _observations.text.trim(),
          'measurements': _measurements.text.trim(),
          'remarks': _remarks.text.trim(),
        });
      } else {
        insp = _existing!;
      }
      if (_pendingPhotos.isNotEmpty) {
        final files = _pendingPhotos
            .map((p) => MultipartFile.fromBytes(p.bytes, filename: p.filename))
            .toList();
        insp = await api.uploadPhotos(widget.projectId, files);
      }
      ref.invalidate(projectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection saved successfully')),
        );
        setState(() {
          _existing = insp;
          _pendingPhotos = [];
        });
      }
    } on DioException catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPhotos() async {
    final photos = await PhotoService.pickPhotos();
    setState(() => _pendingPhotos.addAll(photos));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: LoadingState(message: 'Loading inspection…'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Site inspection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: AppColors.brand),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Inspection date', style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              DateFormat.yMMMEd().format(_date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.inkSubtle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FormSection(
                  title: 'Field notes',
                  children: [
                    TextField(
                      controller: _observations,
                      decoration: const InputDecoration(
                        labelText: 'Observations',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    TextField(
                      controller: _measurements,
                      decoration: const InputDecoration(
                        labelText: 'Measurements',
                        hintText: 'Area, dimensions, counts…',
                      ),
                      maxLines: 2,
                    ),
                    TextField(
                      controller: _remarks,
                      decoration: const InputDecoration(labelText: 'Remarks'),
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'SITE PHOTOS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.inkSubtle,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_existing != null && _existing!.photos.isNotEmpty)
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existing!.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final p = _existing!.photos[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: Image.network(
                            AppConfig.uploadUrl(p.filePath),
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                if (_pendingPhotos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _pendingPhotos
                        .map(
                          (p) => Chip(
                            label: Text(p.filename, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => _pendingPhotos.remove(p)),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add photos'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InlineErrorBanner(message: _error!),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_existing == null ? 'Submit inspection' : 'Save & upload photos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
