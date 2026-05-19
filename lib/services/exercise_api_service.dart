import 'dart:convert';

import '../models/exercise.dart';
import 'api_service.dart';

class ExerciseApiService {
  ExerciseApiService._();
  static final ExerciseApiService instance = ExerciseApiService._();

  final ApiService _api = ApiService.instance;

  Future<List<Exercise>> listExercises() async {
    final res = await _api.get('/exercises');
    if (res.statusCode != 200) return const [];

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded['data'] as List<dynamic>? ?? const []);
    return list
        .map((e) => Exercise.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<Exercise?> createCustomExercise(Exercise exercise) async {
    final res = await _api.post('/exercises', exercise.toApiCreate());
    if (res.statusCode != 201) return null;

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final created = data?['exercise'] as Map<String, dynamic>?;
    if (created == null) return null;
    return Exercise.fromApi(created);
  }

  Future<bool> deleteExercise(String id) async {
    final res = await _api.delete('/exercises/$id');
    return res.statusCode == 200;
  }
}
