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
    this.photos = const [],
  });

  final int inspectionId;
  final int projectId;
  final String? inspectionDate;
  final String? observations;
  final String? measurements;
  final String? remarks;
  final List<PhotoModel> photos;

  factory InspectionModel.fromJson(Map<String, dynamic> j) => InspectionModel(
        inspectionId: j['inspection_id'] as int,
        projectId: j['project_id'] as int,
        inspectionDate: j['inspection_date'] as String?,
        observations: j['observations'] as String?,
        measurements: j['measurements'] as String?,
        remarks: j['remarks'] as String?,
        photos: (j['photos'] as List<dynamic>? ?? [])
            .map((p) => PhotoModel.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class PhotoModel {
  PhotoModel({required this.photoId, required this.filePath});

  final int photoId;
  final String filePath;

  factory PhotoModel.fromJson(Map<String, dynamic> j) => PhotoModel(
        photoId: j['photo_id'] as int,
        filePath: j['file_path'] as String,
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
  });

  final int reportId;
  final int projectId;
  final String status;
  final double? calculatedValue;
  final String? reportContent;

  factory ReportModel.fromJson(Map<String, dynamic> j) => ReportModel(
        reportId: j['report_id'] as int,
        projectId: j['project_id'] as int,
        status: j['status'] as String,
        calculatedValue: j['calculated_value'] != null
            ? double.parse(j['calculated_value'].toString())
            : null,
        reportContent: j['report_content'] as String?,
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
}
