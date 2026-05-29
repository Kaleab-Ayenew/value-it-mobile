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
    return (r.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> pendingUsers() async {
    final r = await _dio.get('/users/pending');
    return (r.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> approveUser(int id, bool approved) async {
    final r = await _dio.patch('/users/$id/approval', data: {'approved': approved});
    return UserModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ClientModel>> clients() async {
    final r = await _dio.get('/clients');
    return (r.data as List).map((e) => ClientModel.fromJson(e)).toList();
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final r = await _dio.post('/clients', data: data);
    return ClientModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<ProjectModel>> projects() async {
    final r = await _dio.get('/projects');
    return (r.data as List).map((e) => ProjectModel.fromJson(e)).toList();
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    final r = await _dio.post('/projects', data: data);
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
    return (r.data as List).map((e) => MaterialModel.fromJson(e)).toList();
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
}
