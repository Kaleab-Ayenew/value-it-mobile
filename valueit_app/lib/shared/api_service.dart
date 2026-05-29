import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import 'models.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.watch(dioProvider));
});

class ApiService {
  ApiService(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return r.data as Map<String, dynamic>;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final r = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      'phone_number': phoneNumber,
    });
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<UserModel> me() async {
    final r = await _dio.get('/auth/me');
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> users({String? role, String? status}) async {
    final r = await _dio.get('/users', queryParameters: {
      if (role != null) 'role': role,
      if (status != null) 'status': status,
    });
    return (r.data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserAvailabilityModel>> userAvailability(String role) async {
    final r = await _dio.get('/users/availability', queryParameters: {'role': role});
    return (r.data as List)
        .map((e) => UserAvailabilityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.patch('/users/me/fcm-token', data: {'fcm_token': token});
  }

  Future<UserModel> updateUserStatus(int id, String accountStatus) async {
    final r = await _dio.patch('/users/$id/status', data: {'account_status': accountStatus});
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<UserModel>> pendingUsers() async {
    final r = await _dio.get('/users/pending');
    return (r.data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> approveUser(int id, bool approved) async {
    final r = await _dio.patch('/users/$id/approval', data: {'approved': approved});
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ClientModel>> clients() async {
    final r = await _dio.get('/clients');
    return (r.data as List).map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final r = await _dio.post('/clients', data: data);
    return ClientModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ProjectModel>> projects({
    String? q,
    String? status,
    bool includeArchived = false,
  }) async {
    final r = await _dio.get('/projects', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null) 'status': status,
      if (includeArchived) 'include_archived': true,
    });
    return (r.data as List).map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectDetailModel> projectDetail(int id) async {
    final r = await _dio.get('/projects/$id/detail');
    return ProjectDetailModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    final r = await _dio.post('/projects', data: data);
    return ProjectModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProjectModel> updateProject(int id, Map<String, dynamic> data) async {
    final r = await _dio.patch('/projects/$id', data: data);
    return ProjectModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ProjectModel> assignProject(int id, {int? valuerId, int? inspectorId}) async {
    final r = await _dio.patch('/projects/$id/assign', data: {
      if (valuerId != null) 'valuer_id': valuerId,
      if (inspectorId != null) 'inspector_id': inspectorId,
    });
    return ProjectModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<InspectionModel> submitInspection(int projectId, Map<String, dynamic> data) async {
    final r = await _dio.post('/projects/$projectId/inspection', data: data);
    return InspectionModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<InspectionModel> getInspection(int projectId) async {
    final r = await _dio.get('/projects/$projectId/inspection');
    return InspectionModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<InspectionModel> uploadPhotos(int projectId, List<MultipartFile> files) async {
    final form = FormData();
    for (final f in files) {
      form.files.add(MapEntry('files', f));
    }
    final r = await _dio.post(
      '/projects/$projectId/inspection/photos',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return InspectionModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<MaterialModel>> materials() async {
    final r = await _dio.get('/materials');
    return (r.data as List).map((e) => MaterialModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MaterialModel> createMaterial(Map<String, dynamic> data) async {
    final r = await _dio.post('/materials', data: data);
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MaterialModel> updateMaterial(int id, Map<String, dynamic> data) async {
    final r = await _dio.patch('/materials/$id', data: data);
    return MaterialModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteMaterial(int id) async {
    await _dio.delete('/materials/$id');
  }

  Future<int> importMaterialsCsv(MultipartFile file) async {
    final form = FormData()..files.add(MapEntry('file', file));
    final r = await _dio.post(
      '/materials/import',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (r.data as Map<String, dynamic>)['imported'] as int? ?? 0;
  }

  Future<ReportModel> submitReport(int projectId, Map<String, dynamic> data) async {
    final r = await _dio.post('/projects/$projectId/report', data: data);
    return ReportModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ReportModel> getReport(int projectId) async {
    final r = await _dio.get('/projects/$projectId/report');
    return ReportModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ReportModel> approveReport(int projectId) async {
    final r = await _dio.patch('/projects/$projectId/report/approve');
    return ReportModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ReportModel> rejectReport(int projectId, String feedback) async {
    final r = await _dio.patch('/projects/$projectId/report/reject', data: {'feedback': feedback});
    return ReportModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Uint8List> downloadReportPdf(int projectId) async {
    final r = await _dio.get(
      '/projects/$projectId/report/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(r.data as List<int>);
  }

  Future<void> emailReport(int projectId, String toEmail) async {
    await _dio.post('/projects/$projectId/report/email', data: {'to_email': toEmail});
  }

  Future<List<NotificationModel>> notifications() async {
    final r = await _dio.get('/notifications');
    return (r.data as List)
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.post('/notifications/read-all');
  }

  Future<List<ChatMessageModel>> chatMessages(int projectId) async {
    final r = await _dio.get('/projects/$projectId/chat');
    return (r.data as List)
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessageModel> sendChatMessage(int projectId, String content) async {
    final r = await _dio.post('/projects/$projectId/chat', data: {'message_content': content});
    return ChatMessageModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AnalyticsOverviewModel> analyticsOverview() async {
    final r = await _dio.get('/analytics/overview');
    return AnalyticsOverviewModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AuditLogModel>> auditLogs({int limit = 50}) async {
    final r = await _dio.get('/audit', queryParameters: {'limit': limit});
    return (r.data as List).map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
