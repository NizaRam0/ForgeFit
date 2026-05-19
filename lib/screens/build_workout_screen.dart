import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';

class BuildWorkoutScreen extends StatefulWidget {
  final WorkoutTemplate? existing;
  const BuildWorkoutScreen({super.key, this.existing});

  @override
  State<BuildWorkoutScreen> createState() => _BuildWorkoutScreenState();
}

class _BuildWorkoutScreenState extends State<BuildWorkoutScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<WorkoutExercise> _exercises = [];
  final List<String> _selectedMuscles = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _descController.text = widget.existing!.description;
      _exercises.addAll(widget.existing!.exercises);
      _selectedMuscles.addAll(widget.existing!.muscleGroups);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateMuscles() {
    _selectedMuscles.clear();
    for (final ex in _exercises) {
      if (!_selectedMuscles.contains(ex.muscleGroup)) {
        _selectedMuscles.add(ex.muscleGroup);
      }
    }
  }

  Future<void> _addExercise() async {
    final provider = context.read<ExerciseProvider>();
    String filterMuscle = 'All';

    final Exercise? selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final filtered = filterMuscle == 'All'
              ? provider.allExercises
              : provider.allExercises.where((e) => e.muscleGroup == filterMuscle).toList();

          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Select Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: ['All', ...AppConstants.muscleGroups].map((m) {
                      final sel = filterMuscle == m;
                      return GestureDetector(
                        onTap: () => setState(() => filterMuscle = m),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? AppTheme.primary : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(m, style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textSecondary,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final ex = filtered[i];
                      return ListTile(
                        title: Text(ex.name),
                        subtitle: Text('${ex.muscleGroup} • ${ex.equipment}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        onTap: () => Navigator.pop(ctx, ex),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selected != null) {
      _showSetRepDialog(selected);
    }
  }

  void _showSetRepDialog(Exercise exercise) {
    int sets = 3;
    int reps = 10;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: Text(exercise.name, style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sets:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                        onPressed: () => setState(() { if (sets > 1) sets--; }),
                      ),
                      Text('$sets', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                        onPressed: () => setState(() => sets++),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reps:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                        onPressed: () => setState(() { if (reps > 1) reps--; }),
                      ),
                      Text('$reps', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                        onPressed: () => setState(() => reps++),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                this.setState(() {
                  _exercises.add(WorkoutExercise(
                    exerciseId: exercise.id,
                    exerciseName: exercise.name,
                    muscleGroup: exercise.muscleGroup,
                    sets: sets,
                    targetReps: reps,
                  ));
                  _updateMuscles();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a workout name')),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final provider = context.read<WorkoutProvider>();
    final template = WorkoutTemplate(
      id: widget.existing?.id ?? provider.generateId(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      muscleGroups: _selectedMuscles,
      exercises: _exercises,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    await provider.addTemplate(template);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workout saved!'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing != null ? 'Edit Workout' : 'Build Workout'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    hintText: 'Workout Name',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 18),
                  ),
                ),
                TextField(
                  controller: _descController,
                  style: const TextStyle(color: AppTheme.textSecondary),
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 8),
                if (_exercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Tap + to add exercises', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                ...List.generate(_exercises.length, (i) {
                  final ex = _exercises[i];
                  return Dismissible(
                    key: Key('$i${ex.exerciseId}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline, color: AppTheme.error),
                    ),
                    onDismissed: (_) => setState(() {
                      _exercises.removeAt(i);
                      _updateMuscles();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.exerciseName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${ex.sets} sets × ${ex.targetReps} reps',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(ex.muscleGroup, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add, color: AppTheme.primary),
                label: const Text('Add Exercise', style: TextStyle(color: AppTheme.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _addExercise,
              ),
            ),
          ),
        ],
      ),
    );
  }
}