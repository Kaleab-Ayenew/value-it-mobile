import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OfflineInspectionDraft {
  OfflineInspectionDraft({
    required this.projectId,
    required this.inspectionDate,
    required this.observations,
    required this.measurements,
    required this.remarks,
    required this.checklistJson,
    required this.savedAt,
  });

  final int projectId;
  final String inspectionDate;
  final String observations;
  final String measurements;
  final String remarks;
  final String checklistJson;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'inspection_date': inspectionDate,
        'observations': observations,
        'measurements': measurements,
        'remarks': remarks,
        'checklist_json': checklistJson,
        'saved_at': savedAt.toIso8601String(),
      };

  factory OfflineInspectionDraft.fromJson(Map<String, dynamic> j) =>
      OfflineInspectionDraft(
        projectId: j['project_id'] as int,
        inspectionDate: j['inspection_date'] as String,
        observations: j['observations'] as String? ?? '',
        measurements: j['measurements'] as String? ?? '',
        remarks: j['remarks'] as String? ?? '',
        checklistJson: j['checklist_json'] as String? ?? '[]',
        savedAt: DateTime.parse(j['saved_at'] as String),
      );
}

class OfflineInspectionStore {
  static String _key(int projectId) => 'inspection_draft_$projectId';

  static Future<void> save(OfflineInspectionDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(draft.projectId), jsonEncode(draft.toJson()));
  }

  static Future<OfflineInspectionDraft?> load(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(projectId));
    if (raw == null) return null;
    return OfflineInspectionDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clear(int projectId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(projectId));
  }
}
