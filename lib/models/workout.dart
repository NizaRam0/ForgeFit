import 'dart:convert';

/// A single set entry: weight + reps
class SetEntry {
  final double weight;
  final int reps;
  final bool completed;

  SetEntry({required this.weight, required this.reps, this.completed = false});

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'reps': reps,
        'completed': completed ? 1 : 0,
      };

  factory SetEntry.fromMap(Map<String, dynamic> m) => SetEntry(
        weight: (m['weight'] as num).toDouble(),
        reps: m['reps'] as int,
        completed: (m['completed'] ?? 0) == 1,
      );

  factory SetEntry.fromApi(Map<String, dynamic> m) => SetEntry(
        weight: (m['weight'] as num).toDouble(),
        reps: (m['reps'] as num).toInt(),
        completed: m['completed'] == true || m['completed'] == 1,
      );

  Map<String, dynamic> toApiCreate({required int sortOrder}) => {
        'weight': weight,
        'reps': reps,
        'completed': completed,
        'sort_order': sortOrder,
      };

  SetEntry copyWith({double? weight, int? reps, bool? completed}) => SetEntry(
        weight: weight ?? this.weight,
        reps: reps ?? this.reps,
        completed: completed ?? this.completed,
      );
}

/// An exercise within a workout template
class WorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int sets;
  final int targetReps;
  final double? lastWeight; // for progressive overload reference
  List<SetEntry> loggedSets;

  WorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.sets,
    required this.targetReps,
    this.lastWeight,
    List<SetEntry>? loggedSets,
  }) : loggedSets = loggedSets ?? [];

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'targetReps': targetReps,
        'lastWeight': lastWeight,
        'loggedSets': jsonEncode(loggedSets.map((s) => s.toMap()).toList()),
      };

  factory WorkoutExercise.fromMap(Map<String, dynamic> m) {
    List<SetEntry> sets = [];
    if (m['loggedSets'] != null) {
      final decoded = jsonDecode(m['loggedSets'] as String) as List;
      sets = decoded
          .map((s) => SetEntry.fromMap(s as Map<String, dynamic>))
          .toList();
    }
    return WorkoutExercise(
      exerciseId: m['exerciseId'],
      exerciseName: m['exerciseName'],
      muscleGroup: m['muscleGroup'] ?? '',
      sets: m['sets'] as int,
      targetReps: m['targetReps'] as int,
      lastWeight:
          m['lastWeight'] != null ? (m['lastWeight'] as num).toDouble() : null,
      loggedSets: sets,
    );
  }

  factory WorkoutExercise.fromApi(Map<String, dynamic> m) {
    // 'sets' from the server may be a list of set objects (for logs) or an
    // integer count (for templates). Handle both without throwing.
    final setsField = m['sets'];
    final rawSets =
        setsField is List ? setsField.cast<dynamic>() : const <dynamic>[];
    final setsCount = (m['sets_count'] as num?)?.toInt() ??
        (setsField is num ? setsField.toInt() : rawSets.length);

    return WorkoutExercise(
      exerciseId: (m['exercise_id'] ?? '').toString(),
      exerciseName:
          (m['exercise_name'] ?? m['exercise']?['name'] ?? '').toString(),
      muscleGroup: (m['muscle_group'] ?? m['exercise']?['muscle_group'] ?? '')
          .toString(),
      sets: setsCount,
      targetReps: (m['target_reps'] as num?)?.toInt() ?? 0,
      loggedSets: rawSets
          .whereType<Map<String, dynamic>>()
          .map(SetEntry.fromApi)
          .toList(),
    );
  }

  Map<String, dynamic> toApiTemplateCreate({required int sortOrder}) => {
        'exercise_id': exerciseId,
        'sets': sets,
        'target_reps': targetReps,
        'sort_order': sortOrder,
      };

  Map<String, dynamic> toApiLogCreate({required int sortOrder}) => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'muscle_group': muscleGroup,
        'sort_order': sortOrder,
        'sets': [
          for (int i = 0; i < loggedSets.length; i++)
            loggedSets[i].toApiCreate(sortOrder: i),
        ],
      };

  WorkoutExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    String? muscleGroup,
    int? sets,
    int? targetReps,
    double? lastWeight,
    List<SetEntry>? loggedSets,
  }) =>
      WorkoutExercise(
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        sets: sets ?? this.sets,
        targetReps: targetReps ?? this.targetReps,
        lastWeight: lastWeight ?? this.lastWeight,
        loggedSets: loggedSets ?? this.loggedSets,
      );

  double get volume => loggedSets.fold(0, (sum, s) => sum + s.weight * s.reps);
  double get maxWeight => loggedSets.isEmpty
      ? 0
      : loggedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
}

/// A workout template (saved plan)
class WorkoutTemplate {
  final String id;
  final String name;
  final String description;
  final List<String> muscleGroups;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final bool isAiGenerated;

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.description = '',
    required this.muscleGroups,
    required this.exercises,
    required this.createdAt,
    this.isAiGenerated = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'muscleGroups': jsonEncode(muscleGroups),
        'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
        'createdAt': createdAt.toIso8601String(),
        'isAiGenerated': isAiGenerated ? 1 : 0,
      };

  factory WorkoutTemplate.fromMap(Map<String, dynamic> m) {
    final rawExercises = jsonDecode(m['exercises'] as String) as List;
    final rawMuscles = jsonDecode(m['muscleGroups'] as String) as List;
    return WorkoutTemplate(
      id: m['id'],
      name: m['name'],
      description: m['description'] ?? '',
      muscleGroups: rawMuscles.cast<String>(),
      exercises: rawExercises
          .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(m['createdAt']),
      isAiGenerated: (m['isAiGenerated'] ?? 0) == 1,
    );
  }

  factory WorkoutTemplate.fromApi(Map<String, dynamic> m) {
    final apiExercises = (m['exercises'] as List<dynamic>? ?? const []);
    return WorkoutTemplate(
      id: m['id'].toString(),
      name: (m['name'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      muscleGroups: (m['muscle_groups'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      exercises: apiExercises.whereType<Map<String, dynamic>>().map((e) {
        final exercise = (e['exercise'] as Map<String, dynamic>? ?? const {});
        final eSets = e['sets'];
        final setsCount = (e['sets_count'] as num?)?.toInt() ??
            (eSets is num ? eSets.toInt() : null) ??
            (eSets is List ? eSets.length : 0);
        return WorkoutExercise(
          exerciseId: (exercise['id'] ?? '').toString(),
          exerciseName: (exercise['name'] ?? '').toString(),
          muscleGroup: (exercise['muscle_group'] ?? '').toString(),
          sets: setsCount,
          targetReps: (e['target_reps'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
          DateTime.now(),
      isAiGenerated: m['is_ai_generated'] == true || m['is_ai_generated'] == 1,
    );
  }

  Map<String, dynamic> toApiCreate() => {
        'name': name,
        'description': description,
        'is_ai_generated': isAiGenerated,
        'muscle_groups': muscleGroups,
        'exercises': [
          for (int i = 0; i < exercises.length; i++)
            exercises[i].toApiTemplateCreate(sortOrder: i),
        ],
      };
}

/// A completed workout session log
class WorkoutLog {
  final String id;
  final String templateId;
  final String templateName;
  final DateTime date;
  final Duration duration;
  final List<WorkoutExercise> exercises;
  final String notes;
  final List<String> muscleGroups;

  WorkoutLog({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.date,
    required this.duration,
    required this.exercises,
    this.notes = '',
    required this.muscleGroups,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'templateId': templateId,
        'templateName': templateName,
        'date': date.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
        'notes': notes,
        'muscleGroups': jsonEncode(muscleGroups),
      };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) {
    final rawExercises = jsonDecode(m['exercises'] as String) as List;
    final rawMuscles = jsonDecode(m['muscleGroups'] as String) as List;
    return WorkoutLog(
      id: m['id'],
      templateId: m['templateId'],
      templateName: m['templateName'],
      date: DateTime.parse(m['date']),
      duration: Duration(seconds: m['durationSeconds'] as int),
      exercises: rawExercises
          .map((e) => WorkoutExercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: m['notes'] ?? '',
      muscleGroups: rawMuscles.cast<String>(),
    );
  }

  factory WorkoutLog.fromApi(Map<String, dynamic> m) {
    final apiExercises = (m['exercises'] as List<dynamic>? ?? const []);
    return WorkoutLog(
      id: m['id'].toString(),
      templateId: (m['template_id'] ?? '').toString(),
      templateName: (m['template_name'] ?? '').toString(),
      date: DateTime.tryParse((m['date'] ?? '').toString()) ?? DateTime.now(),
      duration:
          Duration(seconds: (m['duration_seconds'] as num?)?.toInt() ?? 0),
      exercises: apiExercises
          .whereType<Map<String, dynamic>>()
          .map((e) => WorkoutExercise.fromApi(e))
          .toList(),
      notes: (m['notes'] ?? '').toString(),
      muscleGroups: (m['muscle_groups'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toApiCreate() => {
        'template_id': templateId.isEmpty ? null : templateId,
        'template_name': templateName,
        'date': date.toIso8601String(),
        'duration_seconds': duration.inSeconds,
        'notes': notes,
        'muscle_groups': muscleGroups,
        'exercises': [
          for (int i = 0; i < exercises.length; i++)
            exercises[i].toApiLogCreate(sortOrder: i),
        ],
      };

  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.volume);
  int get totalSets => exercises.fold(0, (sum, e) => sum + e.loggedSets.length);
}
