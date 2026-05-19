import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../services/exercise_api_service.dart';
import '../utils/app_constants.dart';

class ExerciseProvider extends ChangeNotifier {
  List<Exercise> _exercises = [];
  String _selectedMuscle = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  List<Exercise> get exercises => _filteredExercises;
  List<Exercise> get allExercises => _exercises;
  String get selectedMuscle => _selectedMuscle;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  List<Exercise> get _filteredExercises {
    var list = _exercises;
    if (_selectedMuscle != 'All') {
      list = list.where((e) => e.muscleGroup == _selectedMuscle).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.muscleGroup.toLowerCase().contains(q) ||
              e.equipment.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<String> get muscleGroupsWithAll => ['All', ...AppConstants.muscleGroups];

  Future<void> loadExercises() async {
    _isLoading = true;
    notifyListeners();

    _exercises = await ExerciseApiService.instance.listExercises();

    _isLoading = false;
    notifyListeners();
  }

  void filterByMuscle(String muscle) {
    _selectedMuscle = muscle;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> addCustomExercise(Exercise exercise) async {
    final created =
        await ExerciseApiService.instance.createCustomExercise(exercise);
    if (created != null) {
      _exercises.add(created);
      notifyListeners();
    }
  }

  Future<void> deleteExercise(String id) async {
    final deleted = await ExerciseApiService.instance.deleteExercise(id);
    if (deleted) {
      _exercises.removeWhere((e) => e.id == id);
      notifyListeners();
    }
  }

  Exercise? getById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Exercise> getByMuscle(String muscle) =>
      _exercises.where((e) => e.muscleGroup == muscle).toList();
}
