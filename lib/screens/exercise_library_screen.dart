import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../models/exercise.dart';
import 'exercise_detail_screen.dart';
import '../../widgets/exercise_card.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => _showAddExerciseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: provider.search,
            ),
          ),

          // Muscle filter chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: provider.muscleGroupsWithAll.length,
              itemBuilder: (ctx, i) {
                final muscle = provider.muscleGroupsWithAll[i];
                final selected = provider.selectedMuscle == muscle;
                return GestureDetector(
                  onTap: () => provider.filterByMuscle(muscle),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.primary : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      muscle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Exercise count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${provider.exercises.length} exercises',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : provider.exercises.isEmpty
                    ? const Center(child: Text('No exercises found', style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.exercises.length,
                        itemBuilder: (ctx, i) {
                          final exercise = provider.exercises[i];
                          return ExerciseCard(
                            exercise: exercise,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ExerciseDetailScreen(exercise: exercise),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    final nameController = TextEditingController();
    final instructionsController = TextEditingController();
    final formTipsController = TextEditingController();
    String selectedMuscle = AppConstants.muscleGroups.first;
    String selectedDifficulty = 'Beginner';
    String selectedEquipment = 'Dumbbells';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add Custom Exercise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Exercise Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMuscle,
                  dropdownColor: AppTheme.surfaceCard,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Muscle Group'),
                  items: AppConstants.muscleGroups.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => selectedMuscle = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: formTipsController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Form Tips'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      final ex = Exercise(
                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        muscleGroup: selectedMuscle,
                        difficulty: selectedDifficulty,
                        equipment: selectedEquipment,
                        instructions: instructionsController.text.trim(),
                        formTips: formTipsController.text.trim(),
                        isCustom: true,
                      );
                      await context.read<ExerciseProvider>().addCustomExercise(ex);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Exercise'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}