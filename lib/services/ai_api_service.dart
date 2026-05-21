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
      final res = await _api.post('/ai/generate-plan', {}, timeoutSeconds: 90);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final plan = data['data']?['plan'] as Map<String, dynamic>?;
        if (plan != null &&
            plan.containsKey('planName') &&
            plan['days'] is List &&
            (plan['days'] as List).isNotEmpty) {
          return plan;
        }
      }
    } catch (_) {}
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
    // Push Day: 3 chest + 2 shoulders + 2 triceps + 1 traps = 8 exercises
    const pushDay = {
      'dayName': 'Push Day',
      'muscleGroups': ['Chest', 'Shoulders', 'Triceps', 'Traps'],
      'exercises': [
        {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 6},
        {'name': 'Incline Dumbbell Press', 'sets': 3, 'reps': 10},
        {'name': 'Dumbbell Fly', 'sets': 3, 'reps': 12},
        {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
        {'name': 'Lateral Raise', 'sets': 3, 'reps': 12},
        {'name': 'Tricep Pushdown', 'sets': 3, 'reps': 12},
        {'name': 'Skull Crusher', 'sets': 3, 'reps': 10},
        {'name': 'Barbell Shrug', 'sets': 3, 'reps': 15},
      ],
    };

    // Pull Day: 3 back + 2 biceps + 2 rear/forearms + 1 traps = 8 exercises
    const pullDay = {
      'dayName': 'Pull Day',
      'muscleGroups': ['Back', 'Biceps', 'Traps'],
      'exercises': [
        {'name': 'Barbell Row', 'sets': 4, 'reps': 6},
        {'name': 'Pull Up', 'sets': 3, 'reps': 8},
        {'name': 'Seated Cable Row', 'sets': 3, 'reps': 10},
        {'name': 'Barbell Curl', 'sets': 3, 'reps': 10},
        {'name': 'Hammer Curl', 'sets': 3, 'reps': 12},
        {'name': 'Face Pull', 'sets': 3, 'reps': 15},
        {'name': 'Rear Delt Fly', 'sets': 3, 'reps': 15},
        {'name': 'Barbell Shrug', 'sets': 4, 'reps': 15},
      ],
    };

    // Leg Day: heavy compounds + isolation for good intensity
    const legDay = {
      'dayName': 'Leg Day',
      'muscleGroups': ['Quadriceps', 'Hamstrings', 'Glutes', 'Calves'],
      'exercises': [
        {'name': 'Barbell Squat', 'sets': 4, 'reps': 6},
        {'name': 'Romanian Deadlift', 'sets': 4, 'reps': 8},
        {'name': 'Leg Press', 'sets': 3, 'reps': 10},
        {'name': 'Bulgarian Split Squat', 'sets': 3, 'reps': 10},
        {'name': 'Leg Curl', 'sets': 3, 'reps': 12},
        {'name': 'Leg Extension', 'sets': 3, 'reps': 15},
        {'name': 'Calf Raise', 'sets': 4, 'reps': 15},
      ],
    };

    // Upper Body: 3 chest + 3 back + 2 shoulders + 1 traps = 9 exercises
    const upperDay = {
      'dayName': 'Upper Body',
      'muscleGroups': ['Chest', 'Back', 'Shoulders', 'Traps'],
      'exercises': [
        {'name': 'Barbell Bench Press', 'sets': 4, 'reps': 6},
        {'name': 'Barbell Row', 'sets': 4, 'reps': 6},
        {'name': 'Incline Dumbbell Press', 'sets': 3, 'reps': 8},
        {'name': 'Pull Up', 'sets': 3, 'reps': 8},
        {'name': 'Dumbbell Fly', 'sets': 3, 'reps': 12},
        {'name': 'Seated Cable Row', 'sets': 3, 'reps': 10},
        {'name': 'Overhead Press', 'sets': 3, 'reps': 10},
        {'name': 'Lateral Raise', 'sets': 3, 'reps': 12},
        {'name': 'Barbell Shrug', 'sets': 3, 'reps': 15},
      ],
    };

    // Lower Body: high-intensity legs
    const lowerDay = {
      'dayName': 'Lower Body',
      'muscleGroups': ['Quadriceps', 'Hamstrings', 'Glutes'],
      'exercises': [
        {'name': 'Deadlift', 'sets': 4, 'reps': 5},
        {'name': 'Front Squat', 'sets': 3, 'reps': 8},
        {'name': 'Leg Press', 'sets': 3, 'reps': 12},
        {'name': 'Bulgarian Split Squat', 'sets': 3, 'reps': 10},
        {'name': 'Leg Curl', 'sets': 3, 'reps': 12},
        {'name': 'Glute Bridge', 'sets': 3, 'reps': 15},
        {'name': 'Calf Raise', 'sets': 4, 'reps': 15},
      ],
    };

    // Push Day B (for 6-day programs)
    const pushDayB = {
      'dayName': 'Push Day B',
      'muscleGroups': ['Chest', 'Shoulders', 'Triceps', 'Traps'],
      'exercises': [
        {'name': 'Dumbbell Bench Press', 'sets': 4, 'reps': 8},
        {'name': 'Cable Crossover', 'sets': 3, 'reps': 12},
        {'name': 'Incline Barbell Press', 'sets': 3, 'reps': 8},
        {'name': 'Dumbbell Shoulder Press', 'sets': 3, 'reps': 10},
        {'name': 'Arnold Press', 'sets': 3, 'reps': 12},
        {'name': 'Tricep Overhead Extension', 'sets': 3, 'reps': 12},
        {'name': 'Diamond Push Up', 'sets': 3, 'reps': 15},
        {'name': 'Dumbbell Shrug', 'sets': 3, 'reps': 15},
      ],
    };

    final allDays = [pushDay, pullDay, legDay, upperDay, lowerDay, pushDayB];
    final days = allDays.take(profile.workoutsPerWeek.clamp(1, 6)).toList();

    return {
      'planName': '${profile.fitnessLevel} ${profile.goal} Program',
      'days': days,
    };
  }
}
