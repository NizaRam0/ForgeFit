import 'dart:convert';

import '../models/user_profile.dart';
import 'api_service.dart';

class AiApiService {
  AiApiService._();
  static final AiApiService instance = AiApiService._();

  final ApiService _api = ApiService.instance;

  Future<String> chat(String userMessage, UserProfile profile) async {
    try {
      final body = {'message': userMessage};
      final res = await _api.post('/ai/chat', body);
      if (res.statusCode == 200) {
        final reply = res.body.trim();
        if (reply.isNotEmpty) return reply;
      }
    } catch (_) {}
    return _fallbackResponse(userMessage);
  }

  Future<Map<String, dynamic>?> generateWorkoutPlan(UserProfile profile) async {
    try {
      // AI inference can take 30-90 seconds — use a generous timeout.
      final res = await _api.post('/ai/generate-plan', {}, timeoutSeconds: 90);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final plan = data['data']?['plan'] as Map<String, dynamic>?;
        // Only return the server plan if it has the expected structure.
        if (plan != null &&
            plan.containsKey('planName') &&
            plan['days'] is List &&
            (plan['days'] as List).isNotEmpty) {
          return plan;
        }
      }
    } catch (_) {}
    // Always fall back to a locally-generated plan so the feature never silently fails.
    return _fallbackPlan(profile);
  }

  Future<String> getOverloadSuggestion({
    required String exerciseName,
    required double lastWeight,
    required int lastReps,
    required int targetReps,
    required UserProfile profile,
  }) async {
    try {
      final res = await _api.post('/ai/overload-suggestion', {
        'exercise_name': exerciseName,
        'last_weight': lastWeight,
        'last_reps': lastReps,
        'target_reps': targetReps,
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data']?['suggestion'] as String?) ??
            _fallbackResponse('');
      }
    } catch (_) {}
    return _fallbackResponse('');
  }

  Future<String> getMissingMusclesSuggestion(
      List<String> recentMuscles, UserProfile profile) async {
    try {
      final res = await _api
          .post('/ai/missing-muscles', {'recent_muscles': recentMuscles});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data']?['suggestion'] as String?) ??
            _fallbackResponse('');
      }
    } catch (_) {}
    return _fallbackResponse('');
  }

  Future<String> getFormAdvice(String exerciseName, UserProfile profile) async {
    try {
      final res =
          await _api.post('/ai/form-advice', {'exercise_name': exerciseName});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return (data['data']?['advice'] as String?) ?? _fallbackResponse('');
      }
    } catch (_) {}
    return _fallbackResponse('');
  }

  String _fallbackResponse(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('form') || msg.contains('technique')) {
      return 'Great question about form! Key principles: keep your core braced, maintain neutral spine, control the eccentric phase (3 seconds down), and prioritize quality over quantity. Consider reducing weight to master the movement first.';
    }
    if (msg.contains('progressive overload') || msg.contains('increase')) {
      return 'For progressive overload, aim to add 2.5kg per week for upper body and 5kg per week for lower body. If you cannot complete all reps with good form, stay at the current weight. Consistency beats intensity.';
    }
    if (msg.contains('rest') || msg.contains('recover')) {
      return 'Rest 90-180 seconds for hypertrophy, 3-5 minutes for strength. Sleep 7-9 hours — that\'s when muscle is actually built. Active recovery (walking, light stretching) on off days is beneficial.';
    }
    return 'I\'m your ForgeFit AI coach! Ask me about exercise form, progressive overload, workout programming, nutrition timing, or recovery.';
  }

  Map<String, dynamic> _fallbackPlan(UserProfile profile) {
    final allDays = [
      {
        'dayName': 'Push Day',
        'muscleGroups': ['Chest', 'Shoulders', 'Triceps'],
        'exercises': [
          {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 8},
          {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
          {'name': 'Incline Dumbbell Press', 'sets': 3, 'reps': 10},
          {'name': 'Lateral Raise', 'sets': 3, 'reps': 12},
          {'name': 'Tricep Pushdown', 'sets': 3, 'reps': 12},
        ],
      },
      {
        'dayName': 'Pull Day',
        'muscleGroups': ['Back', 'Biceps'],
        'exercises': [
          {'name': 'Barbell Row', 'sets': 4, 'reps': 8},
          {'name': 'Pull Up', 'sets': 3, 'reps': 8},
          {'name': 'Seated Cable Row', 'sets': 3, 'reps': 10},
          {'name': 'Face Pull', 'sets': 3, 'reps': 15},
          {'name': 'Barbell Curl', 'sets': 3, 'reps': 10},
        ],
      },
      {
        'dayName': 'Leg Day',
        'muscleGroups': ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves'],
        'exercises': [
          {'name': 'Barbell Squat', 'sets': 4, 'reps': 8},
          {'name': 'Romanian Deadlift', 'sets': 3, 'reps': 10},
          {'name': 'Leg Press', 'sets': 3, 'reps': 12},
          {'name': 'Leg Curl', 'sets': 3, 'reps': 12},
          {'name': 'Calf Raise', 'sets': 4, 'reps': 15},
        ],
      },
      {
        'dayName': 'Upper Body',
        'muscleGroups': ['Chest', 'Back', 'Shoulders'],
        'exercises': [
          {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 6},
          {'name': 'Barbell Row', 'sets': 4, 'reps': 6},
          {'name': 'Overhead Press', 'sets': 3, 'reps': 8},
          {'name': 'Pull Up', 'sets': 3, 'reps': 8},
          {'name': 'Dumbbell Fly', 'sets': 3, 'reps': 12},
        ],
      },
      {
        'dayName': 'Lower Body',
        'muscleGroups': ['Quadriceps', 'Hamstrings', 'Glutes'],
        'exercises': [
          {'name': 'Deadlift', 'sets': 4, 'reps': 5},
          {'name': 'Front Squat', 'sets': 3, 'reps': 8},
          {'name': 'Walking Lunge', 'sets': 3, 'reps': 12},
          {'name': 'Leg Curl', 'sets': 3, 'reps': 12},
          {'name': 'Glute Bridge', 'sets': 3, 'reps': 15},
        ],
      },
      {
        'dayName': 'Full Body A',
        'muscleGroups': ['Chest', 'Back', 'Legs'],
        'exercises': [
          {'name': 'Barbell Squat', 'sets': 3, 'reps': 8},
          {'name': 'Barbell Bench Press', 'sets': 3, 'reps': 8},
          {'name': 'Barbell Row', 'sets': 3, 'reps': 8},
          {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
        ],
      },
    ];

    final days = allDays.take(profile.workoutsPerWeek.clamp(1, 6)).toList();

    return {
      'planName': '${profile.fitnessLevel} ${profile.goal} Program',
      'days': days,
    };
  }
}
