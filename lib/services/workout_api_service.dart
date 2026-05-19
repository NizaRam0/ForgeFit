import 'dart:convert';

import '../models/workout.dart';
import 'api_service.dart';

class WorkoutApiService {
  WorkoutApiService._();
  static final WorkoutApiService instance = WorkoutApiService._();

  final ApiService _api = ApiService.instance;

  Future<List<WorkoutTemplate>> listTemplates() async {
    final res = await _api.get('/templates');
    if (res.statusCode != 200) return const [];

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>? ?? const []);
    return list
        .map((e) => WorkoutTemplate.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutTemplate?> createTemplate(WorkoutTemplate template) async {
    final res = await _api.post('/templates', template.toApiCreate());
    if (res.statusCode != 201) return null;

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final created = data?['template'] as Map<String, dynamic>?;
    if (created == null) return null;
    return WorkoutTemplate.fromApi(created);
  }

  Future<bool> deleteTemplate(String id) async {
    final res = await _api.delete('/templates/$id');
    return res.statusCode == 200;
  }

  Future<List<WorkoutLog>> listLogs() async {
    final res = await _api.get('/logs');
    if (res.statusCode != 200) return const [];

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>? ?? const []);
    return list.map((e) => WorkoutLog.fromApi(e as Map<String, dynamic>)).toList();
  }

  Future<WorkoutLog?> createLog(WorkoutLog log) async {
    final res = await _api.post('/logs', log.toApiCreate());
    if (res.statusCode != 201) return null;

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final created = data?['log'] as Map<String, dynamic>?;
    if (created == null) return null;
    return WorkoutLog.fromApi(created);
  }

  Future<bool> deleteLog(String id) async {
    final res = await _api.delete('/logs/$id');
    return res.statusCode == 200;
  }
}
