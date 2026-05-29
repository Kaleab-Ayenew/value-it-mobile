import 'dart:convert';

class UserModel {
  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.phoneNumber,
  });

  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String accountStatus;
  final String? phoneNumber;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        userId: j['user_id'] as int,
        fullName: j['full_name'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        accountStatus: j['account_status'] as String,
        phoneNumber: j['phone_number'] as String?,
      );

  bool get isActive => accountStatus == 'Active';
  bool get isPending => accountStatus == 'Pending';
}

class UserAvailabilityModel {
  UserAvailabilityModel({
    required this.userId,
    required this.fullName,
    required this.activeProjects,
    required this.available,
  });

  final int userId;
  final String fullName;
  final int activeProjects;
  final bool available;

  factory UserAvailabilityModel.fromJson(Map<String, dynamic> j) => UserAvailabilityModel(
        userId: j['user_id'] as int,
        fullName: j['full_name'] as String,
        activeProjects: j['active_projects'] as int,
        available: j['available'] as bool,
      );
}

class ClientModel {
  ClientModel({
    required this.clientId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.address,
    this.organization,
  });

  final int clientId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? organization;

  factory ClientModel.fromJson(Map<String, dynamic> j) => ClientModel(
        clientId: j['client_id'] as int,
        fullName: j['full_name'] as String,
        email: j['email'] as String?,
        phoneNumber: j['phone_number'] as String?,
        address: j['address'] as String?,
        organization: j['organization'] as String?,
      );
}

class ProjectModel {
  ProjectModel({
    required this.projectId,
    required this.projectName,
    required this.status,
    this.location,
    this.valuationPurpose,
    this.clientId,
    this.valuerId,
    this.inspectorId,
    this.startDate,
    this.endDate,
    this.client,
    this.archived = false,
  });

  final int projectId;
  final String projectName;
  final String status;
  final String? location;
  final String? valuationPurpose;
  final int? clientId;
  final int? valuerId;
  final int? inspectorId;
  final String? startDate;
  final String? endDate;
  final ClientModel? client;
  final bool archived;

  factory ProjectModel.fromJson(Map<String, dynamic> j) => ProjectModel(
        projectId: j['project_id'] as int,
        projectName: j['project_name'] as String,
        status: j['status'] as String,
        location: j['location'] as String?,
        valuationPurpose: j['valuation_purpose'] as String?,
        clientId: j['client_id'] as int?,
        valuerId: j['valuer_id'] as int?,
        inspectorId: j['inspector_id'] as int?,
        startDate: j['start_date'] as String?,
        endDate: j['end_date'] as String?,
        client: j['client'] != null
            ? ClientModel.fromJson(j['client'] as Map<String, dynamic>)
            : null,
        archived: j['archived'] as bool? ?? false,
      );
}

class TimelineEventModel {
  TimelineEventModel({required this.label, this.at, this.detail});

  final String label;
  final DateTime? at;
  final String? detail;

  factory TimelineEventModel.fromJson(Map<String, dynamic> j) => TimelineEventModel(
        label: j['label'] as String,
        at: j['at'] != null ? DateTime.tryParse(j['at'] as String) : null,
        detail: j['detail'] as String?,
      );
}

class ProjectDetailModel extends ProjectModel {
  ProjectDetailModel({
    required super.projectId,
    required super.projectName,
    required super.status,
    super.location,
    super.valuationPurpose,
    super.clientId,
    super.valuerId,
    super.inspectorId,
    super.startDate,
    super.endDate,
    super.client,
    super.archived,
    this.valuerName,
    this.inspectorName,
    this.hasInspection = false,
    this.hasReport = false,
    this.reportStatus,
    this.timeline = const [],
  });

  final String? valuerName;
  final String? inspectorName;
  final bool hasInspection;
  final bool hasReport;
  final String? reportStatus;
  final List<TimelineEventModel> timeline;

  factory ProjectDetailModel.fromJson(Map<String, dynamic> j) => ProjectDetailModel(
        projectId: j['project_id'] as int,
        projectName: j['project_name'] as String,
        status: j['status'] as String,
        location: j['location'] as String?,
        valuationPurpose: j['valuation_purpose'] as String?,
        clientId: j['client_id'] as int?,
        valuerId: j['valuer_id'] as int?,
        inspectorId: j['inspector_id'] as int?,
        startDate: j['start_date'] as String?,
        endDate: j['end_date'] as String?,
        client: j['client'] != null
            ? ClientModel.fromJson(j['client'] as Map<String, dynamic>)
            : null,
        archived: j['archived'] as bool? ?? false,
        valuerName: j['valuer_name'] as String?,
        inspectorName: j['inspector_name'] as String?,
        hasInspection: j['has_inspection'] as bool? ?? false,
        hasReport: j['has_report'] as bool? ?? false,
        reportStatus: j['report_status'] as String?,
        timeline: (j['timeline'] as List<dynamic>? ?? [])
            .map((e) => TimelineEventModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ChecklistItemModel {
  ChecklistItemModel({required this.area, this.condition, this.notes});

  final String area;
  final String? condition;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'area': area,
        'condition': condition,
        'notes': notes,
      };

  factory ChecklistItemModel.fromJson(Map<String, dynamic> j) => ChecklistItemModel(
        area: j['area'] as String,
        condition: j['condition'] as String?,
        notes: j['notes'] as String?,
      );
}

class InspectionModel {
  InspectionModel({
    required this.inspectionId,
    required this.projectId,
    this.inspectionDate,
    this.observations,
    this.measurements,
    this.remarks,
    this.checklistJson,
    this.photos = const [],
  });

  final int inspectionId;
  final int projectId;
  final String? inspectionDate;
  final String? observations;
  final String? measurements;
  final String? remarks;
  final String? checklistJson;
  final List<PhotoModel> photos;

  List<ChecklistItemModel> get checklist {
    if (checklistJson == null || checklistJson!.isEmpty) return [];
    try {
      final list = (jsonDecode(checklistJson!) as List<dynamic>);
      return list.map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  factory InspectionModel.fromJson(Map<String, dynamic> j) => InspectionModel(
        inspectionId: j['inspection_id'] as int,
        projectId: j['project_id'] as int,
        inspectionDate: j['inspection_date']?.toString(),
        observations: j['observations'] as String?,
        measurements: j['measurements'] as String?,
        remarks: j['remarks'] as String?,
        checklistJson: j['checklist_json'] as String?,
        photos: (j['photos'] as List<dynamic>? ?? [])
            .map((p) => PhotoModel.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class PhotoModel {
  PhotoModel({required this.photoId, required this.filePath, this.url});

  final int photoId;
  final String filePath;
  final String? url;

  factory PhotoModel.fromJson(Map<String, dynamic> j) => PhotoModel(
        photoId: j['photo_id'] as int,
        filePath: j['file_path'] as String,
        url: j['url'] as String?,
      );
}

class MaterialModel {
  MaterialModel({
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.unitPrice,
  });

  final int materialId;
  final String materialName;
  final String unit;
  final double unitPrice;

  factory MaterialModel.fromJson(Map<String, dynamic> j) => MaterialModel(
        materialId: j['material_id'] as int,
        materialName: j['material_name'] as String,
        unit: j['unit'] as String,
        unitPrice: double.parse(j['unit_price'].toString()),
      );
}

class ReportModel {
  ReportModel({
    required this.reportId,
    required this.projectId,
    required this.status,
    this.calculatedValue,
    this.reportContent,
    this.managerFeedback,
    this.notes,
    this.lineItems = const [],
  });

  final int reportId;
  final int projectId;
  final String status;
  final double? calculatedValue;
  final String? reportContent;
  final String? managerFeedback;
  final String? notes;
  final List<LineItem> lineItems;

  factory ReportModel.fromJson(Map<String, dynamic> j) => ReportModel(
        reportId: j['report_id'] as int,
        projectId: j['project_id'] as int,
        status: j['status'] as String,
        calculatedValue: j['calculated_value'] != null
            ? double.parse(j['calculated_value'].toString())
            : null,
        reportContent: j['report_content'] as String?,
        managerFeedback: j['manager_feedback'] as String?,
        notes: j['notes'] as String?,
        lineItems: (j['line_items'] as List<dynamic>? ?? [])
            .map((i) => LineItem.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class LineItem {
  LineItem({
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  final String materialName;
  final double quantity;
  final String unit;
  final double unitPrice;

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'material_name': materialName,
        'quantity': quantity,
        'unit': unit,
        'unit_price': unitPrice,
        'total': total,
      };

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
        materialName: j['material_name'] as String,
        quantity: double.parse(j['quantity'].toString()),
        unit: j['unit'] as String,
        unitPrice: double.parse(j['unit_price'].toString()),
      );
}

class NotificationModel {
  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.status,
    this.entityType,
    this.entityId,
    this.createdAt,
  });

  final int notificationId;
  final String title;
  final String message;
  final String status;
  final String? entityType;
  final int? entityId;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        notificationId: j['notification_id'] as int,
        title: j['title'] as String,
        message: j['message'] as String,
        status: j['status'] as String,
        entityType: j['entity_type'] as String?,
        entityId: j['entity_id'] as int?,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
      );
}

class ChatMessageModel {
  ChatMessageModel({
    required this.messageId,
    required this.projectId,
    required this.senderId,
    required this.senderName,
    required this.messageContent,
    required this.sentAt,
  });

  final int messageId;
  final int projectId;
  final int senderId;
  final String senderName;
  final String messageContent;
  final DateTime sentAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        messageId: j['message_id'] as int,
        projectId: j['project_id'] as int,
        senderId: j['sender_id'] as int,
        senderName: j['sender_name'] as String,
        messageContent: j['message_content'] as String,
        sentAt: DateTime.parse(j['sent_at'] as String),
      );
}

class AnalyticsOverviewModel {
  AnalyticsOverviewModel({
    required this.totalProjects,
    required this.pending,
    required this.inProgress,
    required this.completed,
    required this.pendingApprovals,
    required this.pendingReports,
    required this.activeValuers,
    required this.activeInspectors,
  });

  final int totalProjects;
  final int pending;
  final int inProgress;
  final int completed;
  final int pendingApprovals;
  final int pendingReports;
  final int activeValuers;
  final int activeInspectors;

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> j) => AnalyticsOverviewModel(
        totalProjects: j['total_projects'] as int,
        pending: j['pending'] as int,
        inProgress: j['in_progress'] as int,
        completed: j['completed'] as int,
        pendingApprovals: j['pending_approvals'] as int,
        pendingReports: j['pending_reports'] as int,
        activeValuers: j['active_valuers'] as int,
        activeInspectors: j['active_inspectors'] as int,
      );
}

class AuditLogModel {
  AuditLogModel({
    required this.logId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.detail,
    this.createdAt,
    this.actorName,
  });

  final int logId;
  final String action;
  final String entityType;
  final int? entityId;
  final String? detail;
  final DateTime? createdAt;
  final String? actorName;

  factory AuditLogModel.fromJson(Map<String, dynamic> j) => AuditLogModel(
        logId: j['log_id'] as int,
        action: j['action'] as String,
        entityType: j['entity_type'] as String,
        entityId: j['entity_id'] as int?,
        detail: j['detail'] as String?,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'] as String) : null,
        actorName: j['actor_name'] as String?,
      );
}
