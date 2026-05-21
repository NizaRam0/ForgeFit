import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';
import '../services/workout_api_service.dart';

class WorkoutProvider extends ChangeNotifier {
  List<WorkoutTemplate> _templates = [];
  List<WorkoutLog> _logs = [];
  WorkoutLog? _activeWorkout;
  DateTime? _activeStartedAt;
  bool _isLoading = false;
  final _uuid = const Uuid();

  List<WorkoutTemplate> get templates => _templates;
  List<WorkoutLog> get logs => _logs;
  WorkoutLog? get activeWorkout => _activeWorkout;
  DateTime? get activeStartedAt => _activeStartedAt;
  bool get isLoading => _isLoading;
  bool get hasActiveWorkout => _activeWorkout != null;

  Future<void> loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    // Restore the active workout first so it is available even if API calls fail.
    await restoreIfAny();

    try {
      _templates = await WorkoutApiService.instance.listTemplates();
      _logs = await WorkoutApiService.instance.listLogs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── TEMPLATES ────────────────────────────────────────────────────────────
  Future<void> addTemplate(WorkoutTemplate template) async {
    final created = await WorkoutApiService.instance.createTemplate(template);
    if (created != null) {
      _templates.insert(0, created);
      notifyListeners();
    }
  }

  Future<void> clearAiGeneratedTemplates() async {
    final aiTemplates = _templates.where((t) => t.isAiGenerated).toList();
    for (final template in aiTemplates) {
      final deleted =
          await WorkoutApiService.instance.deleteTemplate(template.id);
      if (deleted) {
        _templates.removeWhere((t) => t.id == template.id);
      }
    }
    notifyListeners();
  }

  Future<void> deleteAllTemplates() async {
    final templates = List<WorkoutTemplate>.from(_templates);
    for (final template in templates) {
      final deleted =
          await WorkoutApiService.instance.deleteTemplate(template.id);
      if (deleted) {
        _templates.removeWhere((t) => t.id == template.id);
      }
    }
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    final deleted = await WorkoutApiService.instance.deleteTemplate(id);
    if (deleted) {
      _templates.removeWhere((t) => t.id == id);
      notifyListeners();
    }
  }

  String generateId() => _uuid.v4();

  // ─── ACTIVE WORKOUT (Live Session) ────────────────────────────────────────
  void startWorkout(WorkoutTemplate template) {
    // Copy template and populate lastWeight from history
    _activeWorkout = WorkoutLog(
      id: _uuid.v4(),
      templateId: template.id,
      templateName: template.name,
      date: DateTime.now(),
      duration: Duration.zero,
      exercises: template.exercises
          .map((e) => WorkoutExercise(
                exerciseId: e.exerciseId,
                exerciseName: e.exerciseName,
                muscleGroup: e.muscleGroup,
                sets: e.sets,
                targetReps: e.targetReps,
                loggedSets: [],
              ))
          .toList(),
      muscleGroups: template.muscleGroups,
    );
    _activeStartedAt = DateTime.now();
    _persistActiveWorkout();
    notifyListeners();
  }

  void logSet(int exerciseIndex, SetEntry setEntry) {
    if (_activeWorkout == null) return;
    _activeWorkout!.exercises[exerciseIndex].loggedSets.add(setEntry);
    _persistActiveWorkout();
    notifyListeners();
  }

  void updateSet(int exerciseIndex, int setIndex, SetEntry updatedSet) {
    if (_activeWorkout == null) return;
    _activeWorkout!.exercises[exerciseIndex].loggedSets[setIndex] = updatedSet;
    _persistActiveWorkout();
    notifyListeners();
  }

  void removeSet(int exerciseIndex, int setIndex) {
    if (_activeWorkout == null) return;
    _activeWorkout!.exercises[exerciseIndex].loggedSets.removeAt(setIndex);
    _persistActiveWorkout();
    notifyListeners();
  }

  Future<bool> finishWorkout(Duration duration, String notes) async {
    if (_activeWorkout == null) return false;

    final hasAnySets =
        _activeWorkout!.exercises.any((e) => e.loggedSets.isNotEmpty);
    if (!hasAnySets) return false;

    final finishedLog = WorkoutLog(
      id: _activeWorkout!.id,
      templateId: _activeWorkout!.templateId,
      templateName: _activeWorkout!.templateName,
      date: _activeWorkout!.date,
      duration: duration,
      exercises: _activeWorkout!.exercises,
      notes: notes,
      muscleGroups: _activeWorkout!.muscleGroups,
    );

    final created = await WorkoutApiService.instance.createLog(finishedLog);
    if (created == null) return false;

    _logs.insert(0, created);
    _activeWorkout = null;
    _activeStartedAt = null;
    _clearPersistedActiveWorkout();
    notifyListeners();
    return true;
  }

  void cancelWorkout() {
    _activeWorkout = null;
    _activeStartedAt = null;
    _clearPersistedActiveWorkout();
    notifyListeners();
  }

  // ─── PERSISTENCE ───────────────────────────────────────────────────────
  static const _kActiveKey = 'forgefit_active_workout';

  Future<void> _persistActiveWorkout() async {
    if (_activeWorkout == null || _activeStartedAt == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'workout': _activeWorkout!.toMap(),
      'startedAtMs': _activeStartedAt!.millisecondsSinceEpoch,
    });
    await prefs.setString(_kActiveKey, payload);
  }

  Future<void> _clearPersistedActiveWorkout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kActiveKey);
  }

  Future<void> restoreIfAny() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_kActiveKey)) return;
    try {
      final raw = prefs.getString(_kActiveKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final workoutMap = decoded['workout'] as Map<String, dynamic>;
      final startedAtMs = decoded['startedAtMs'] as int?;
      final restored = WorkoutLog.fromMap(workoutMap);
      _activeWorkout = restored;
      _activeStartedAt = startedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startedAtMs)
          : null;
      notifyListeners();
    } catch (e) {
      // If restore fails, clear any corrupted entry
      await _clearPersistedActiveWorkout();
    }
  }

  // ─── ANALYTICS ────────────────────────────────────────────────────────────

  /// Get all logs sorted by date
  List<WorkoutLog> get sortedLogs {
    final sorted = List<WorkoutLog>.from(_logs);
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Get workout calendar — map of date to muscle groups
  Map<DateTime, List<String>> get calendarData {
    final map = <DateTime, List<String>>{};
    for (final log in _logs) {
      final key = DateTime(log.date.year, log.date.month, log.date.day);
      map[key] = log.muscleGroups;
    }
    return map;
  }

  /// Progress data for a specific exercise (date → max weight)
  List<MapEntry<DateTime, double>> getExerciseProgress(String exerciseId) {
    final data = <MapEntry<DateTime, double>>[];
    for (final log in sortedLogs) {
      for (final ex in log.exercises) {
        if (ex.exerciseId == exerciseId && ex.maxWeight > 0) {
          data.add(MapEntry(log.date, ex.maxWeight));
        }
      }
    }
    return data;
  }

  /// Volume progress per muscle group over time
  Map<String, List<MapEntry<DateTime, double>>> getMuscleVolumeProgress() {
    final map = <String, List<MapEntry<DateTime, double>>>{};
    for (final log in sortedLogs) {
      for (final ex in log.exercises) {
        map.putIfAbsent(ex.muscleGroup, () => []);
        map[ex.muscleGroup]!.add(MapEntry(log.date, ex.volume));
      }
    }
    return map;
  }

  /// Muscles trained in last N days
  List<String> recentMuscles({int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final muscles = <String>{};
    for (final log in _logs) {
      if (log.date.isAfter(cutoff)) {
        muscles.addAll(log.muscleGroups);
      }
    }
    return muscles.toList();
  }

  /// Get last weight used for an exercise
  double? getLastWeight(String exerciseId) {
    for (final log in List.from(_logs.reversed)) {
      for (final ex in log.exercises) {
        if (ex.exerciseId == exerciseId && ex.maxWeight > 0) {
          return ex.maxWeight;
        }
      }
    }
    return null;
  }

  /// Suggested progressive overload weight
  double? getSuggestedWeight(String exerciseId) {
    final last = getLastWeight(exerciseId);
    if (last == null) return null;
    // Add 2.5kg (or 5% whichever is bigger)
    final increment = last * 0.025 > 2.5 ? (last * 0.025).roundToDouble() : 2.5;
    return last + increment;
  }

  /// Total workouts this week
  int get workoutsThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _logs.where((l) => l.date.isAfter(weekStart)).length;
  }

  /// Total volume this week
  double get volumeThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _logs
        .where((l) => l.date.isAfter(weekStart))
        .fold(0, (sum, l) => sum + l.totalVolume);
  }

  /// Workout streak in days
  int get currentStreak {
    if (_logs.isEmpty) return 0;
    int streak = 0;
    final logDates = _logs
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();
    var day = DateTime.now();
    final todayKey = DateTime(day.year, day.month, day.day);
    if (!logDates.contains(todayKey)) {
      day = day.subtract(const Duration(days: 1));
    }
    while (logDates.contains(DateTime(day.year, day.month, day.day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
