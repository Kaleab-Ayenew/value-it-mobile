import 'dart:convert';

import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/design_tokens.dart';
import '../../core/l10n.dart';
import '../../core/offline_inspection.dart';
import '../../shared/api_service.dart';
import '../../shared/models.dart';
import '../../shared/photo_service.dart';
import '../../shared/projects_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/feedback.dart';

class InspectionFormScreen extends ConsumerStatefulWidget {
  const InspectionFormScreen({super.key, required this.projectId});

  final int projectId;

  @override
  ConsumerState<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends ConsumerState<InspectionFormScreen> {
  static const _defaultAreas = ['Foundation', 'Roof', 'Walls', 'Plumbing', 'Electrical'];

  final _observations = TextEditingController();
  final _measurements = TextEditingController();
  final _remarks = TextEditingController();
  final Map<String, TextEditingController> _checklistNotes = {};
  final Map<String, String?> _checklistCondition = {};
  DateTime _date = DateTime.now();
  InspectionModel? _existing;
  List<PickedPhoto> _pendingPhotos = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasOfflineDraft = false;

  @override
  void dispose() {
    _observations.dispose();
    _measurements.dispose();
    _remarks.dispose();
    for (final c in _checklistNotes.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (final a in _defaultAreas) {
      _checklistNotes[a] = TextEditingController();
      _checklistCondition[a] = null;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final insp = await ref.read(apiServiceProvider).getInspection(widget.projectId);
      setState(() {
        _applyInspection(insp);
        _loading = false;
      });
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final draft = await OfflineInspectionStore.load(widget.projectId);
        if (draft != null) {
          setState(() {
            _observations.text = draft.observations;
            _measurements.text = draft.measurements;
            _remarks.text = draft.remarks;
            _date = DateTime.tryParse(draft.inspectionDate) ?? _date;
            _hasOfflineDraft = true;
            _applyChecklistJson(draft.checklistJson);
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() {
          _error = apiErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  void _applyInspection(InspectionModel insp) {
    _existing = insp;
    _observations.text = insp.observations ?? '';
    _measurements.text = insp.measurements ?? '';
    _remarks.text = insp.remarks ?? '';
    if (insp.inspectionDate != null) {
      _date = DateTime.tryParse(insp.inspectionDate!) ?? _date;
    }
    for (final c in insp.checklist) {
      _checklistNotes.putIfAbsent(c.area, () => TextEditingController());
      _checklistCondition[c.area] = c.condition;
      _checklistNotes[c.area]!.text = c.notes ?? '';
    }
  }

  void _applyChecklistJson(String jsonStr) {
    try {
      final list = (jsonDecode(jsonStr) as List<dynamic>)
          .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final c in list) {
        _checklistCondition[c.area] = c.condition;
        _checklistNotes.putIfAbsent(c.area, () => TextEditingController());
        _checklistNotes[c.area]!.text = c.notes ?? '';
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _checklistPayload() {
    return _defaultAreas
        .map((a) => {
              'area': a,
              'condition': _checklistCondition[a],
              'notes': _checklistNotes[a]?.text.trim(),
            })
        .toList();
  }

  Future<void> _saveOffline() async {
    final draft = OfflineInspectionDraft(
      projectId: widget.projectId,
      inspectionDate: DateFormat('yyyy-MM-dd').format(_date),
      observations: _observations.text.trim(),
      measurements: _measurements.text.trim(),
      remarks: _remarks.text.trim(),
      checklistJson: jsonEncode(_checklistPayload()),
      savedAt: DateTime.now(),
    );
    await OfflineInspectionStore.save(draft);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).offlineDraft)),
      );
      setState(() => _hasOfflineDraft = true);
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
          'checklist': _checklistPayload(),
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
      await OfflineInspectionStore.clear(widget.projectId);
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
    final photos = await PhotoService.pickPhotos(compress: true);
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
                FormSection(
                  title: AppStrings.of(context).checklist,
                  children: _defaultAreas.map((area) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        DropdownButtonFormField<String?>(
                          initialValue: _checklistCondition[area],
                          decoration: const InputDecoration(labelText: 'Condition'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('—')),
                            DropdownMenuItem(value: 'Good', child: Text('Good')),
                            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                            DropdownMenuItem(value: 'Poor', child: Text('Poor')),
                          ],
                          onChanged: (v) => setState(() => _checklistCondition[area] = v),
                        ),
                        TextField(
                          controller: _checklistNotes[area],
                          decoration: const InputDecoration(labelText: 'Notes'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    );
                  }).toList(),
                ),
                if (_hasOfflineDraft)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: InlineErrorBanner(message: 'Offline draft on device — submit when connected'),
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
                            AppConfig.photoUrl(filePath: p.filePath, url: p.url),
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
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _saveOffline,
                  icon: const Icon(Icons.cloud_off_outlined),
                  label: const Text('Save offline draft'),
                ),
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
