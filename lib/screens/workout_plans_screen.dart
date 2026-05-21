import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/workout_provider.dart';
import '../providers/user_provider.dart';
import '../providers/exercise_provider.dart';
import '../models/workout.dart';
import '../services/ai_api_service.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';
import 'build_workout_screen.dart';

const Map<String, int> _fitnessLevelRank = {
  'Beginner': 0,
  'Intermediate': 1,
  'Advanced': 2,
};

class WorkoutPlansScreen extends StatelessWidget {
  const WorkoutPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
        actions: [
          if (workoutProvider.templates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined,
                  color: AppTheme.error),
              tooltip: 'Delete All Workouts',
              onPressed: () => _confirmDeleteAll(context),
            ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accent),
            tooltip: 'AI Generate Plan',
            onPressed: () => _showAiGenerateDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuildWorkoutScreen()),
            ),
          ),
        ],
      ),
      body: workoutProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : workoutProvider.templates.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: workoutProvider.templates.length,
                  itemBuilder: (ctx, i) {
                    final template = workoutProvider.templates[i];
                    return _buildTemplateCard(ctx, template, workoutProvider);
                  },
                ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WorkoutTemplate template,
      WorkoutProvider provider) {
    return Dismissible(
      key: Key(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.card(context),
                title: const Text('Delete Workout?'),
                content: Text('Delete "${template.name}"?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete',
                          style: TextStyle(color: AppTheme.error))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => provider.deleteTemplate(template.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: template.isAiGenerated
                ? AppTheme.accent.withOpacity(0.3)
                : AppTheme.border(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (template.isAiGenerated) ...[
                            const Icon(Icons.auto_awesome,
                                size: 14, color: AppTheme.accent),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(template.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ),
                      if (template.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(template.description,
                            style: TextStyle(
                              color: AppTheme.onSubtext(context),
                              fontSize: 13,
                            )),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _startWorkout(context, template),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Start', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: template.muscleGroups.map((m) {
                final color = Color(MuscleGroupColors.colors[m] ?? 0xFFFF6B35);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(m,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '${template.exercises.length} exercises',
              style: TextStyle(color: AppTheme.onSubtext(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context, WorkoutTemplate template) {
    context.read<WorkoutProvider>().startWorkout(template);
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card(context),
            title: const Text('Delete All Workouts?'),
            content: const Text(
              'This will permanently delete every workout plan on this page.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete All',
                    style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    await context.read<WorkoutProvider>().deleteAllTemplates();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All workouts deleted'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center,
              size: 64, color: AppTheme.onSubtext(context)),
          const SizedBox(height: 16),
          const Text('No workouts yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Create your own or let AI build one for you',
            style: TextStyle(color: AppTheme.onSubtext(context)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Build Workout'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuildWorkoutScreen()),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome, color: AppTheme.accent),
                label: const Text('AI Generate',
                    style: TextStyle(color: AppTheme.accent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.accent),
                ),
                onPressed: () => _showAiGenerateDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAiGenerateDialog(BuildContext context) async {
    final user = _profileOrFallback(context.read<UserProvider>().user);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool loading = false;
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            backgroundColor: AppTheme.card(context),
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.accent),
                SizedBox(width: 8),
                Text('AI Workout Plan'),
              ],
            ),
            content: loading
                ? const SizedBox(
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accent),
                        SizedBox(height: 12),
                        Text('Generating your plan...'),
                      ],
                    ),
                  )
                : error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.error, size: 48),
                          const SizedBox(height: 12),
                          const Text('Failed to generate plan',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppTheme.onSubtext(context),
                                  fontSize: 13)),
                        ],
                      )
                    : Text(
                        'Generate a personalized ${user.workoutsPerWeek}-day program '
                        'for ${user.goal} based on your profile?',
                      ),
            actions: loading
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style:
                              TextStyle(color: AppTheme.onSubtext(context))),
                    ),
                    if (error != null)
                      ElevatedButton(
                        onPressed: () => setState(() => error = null),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent),
                        child: const Text('Retry'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => loading = true);
                          try {
                            final plan = await AiApiService.instance
                                .generateWorkoutPlan(user);

                            if (plan == null) {
                              throw Exception('No plan returned from AI');
                            }

                            if (!ctx.mounted) return;

                            final workoutProvider =
                                context.read<WorkoutProvider>();
                            if (workoutProvider.templates.isNotEmpty) {
                              await workoutProvider.deleteAllTemplates();
                            }
                            await _savePlan(context, plan, user);

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('✅ AI workout plan created!'),
                                  backgroundColor: AppTheme.success),
                            );
                          } catch (e, stackTrace) {
                            debugPrint('[AI] Error: $e');
                            debugPrint('[AI] Stack: $stackTrace');
                            setState(() {
                              loading = false;
                              error = e
                                  .toString()
                                  .replaceFirst('Exception: ', '')
                                  .replaceFirst('_AsyncError: ', '');
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent),
                        child: const Text('Generate'),
                      ),
                  ],
          ),
        );
      },
    );
  }

  Future<void> _savePlan(BuildContext context, Map<String, dynamic> plan,
      UserProfile profile) async {
    if (!plan.containsKey('days') || plan['days'] is! List) {
      throw Exception('Invalid plan structure: missing or invalid days');
    }
    if (!plan.containsKey('planName')) {
      throw Exception('Invalid plan structure: missing planName');
    }

    final workoutProvider = context.read<WorkoutProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();
    if (exerciseProvider.allExercises.isEmpty) {
      try {
        await exerciseProvider.loadExercises();
      } catch (e) {
        throw Exception('Failed to load exercises: $e');
      }
    }

    if (exerciseProvider.allExercises.isEmpty) {
      throw Exception(
          'No exercises available in database. Please check your connection.');
    }

    final days = plan['days'] as List;
    if (days.isEmpty) throw Exception('Plan has no days');

    int templatesAdded = 0;

    for (final day in days) {
      if (day is! Map<String, dynamic>) continue;
      final dayMap = day;
      final dayName = dayMap['dayName'] as String? ?? 'Day';
      final rawExercises = dayMap['exercises'] as List? ?? [];
      if (rawExercises.isEmpty) continue;

      final workoutExercises = <WorkoutExercise>[];
      for (final e in rawExercises) {
        if (e is! Map<String, dynamic>) continue;
        final exerciseName = e['name'] as String?;
        if (exerciseName == null) continue;

        final sets = e['sets'] as num?;
        final reps = e['reps'] as num?;
        if (sets == null || reps == null) continue;

        final exactMatches = exerciseProvider.allExercises
            .where((ex) => ex.name.toLowerCase() == exerciseName.toLowerCase())
            .toList();
        final partialMatches = exerciseProvider.allExercises
            .where((ex) =>
                ex.name.toLowerCase().contains(exerciseName.toLowerCase()))
            .toList();

        final found = exactMatches.isNotEmpty
            ? exactMatches.first
            : (partialMatches.isNotEmpty ? partialMatches.first : null);

        if (found == null) continue;

        final userRank = _fitnessLevelRank[profile.fitnessLevel] ?? 0;
        final exerciseRank = _fitnessLevelRank[found.difficulty] ?? 0;
        if (exerciseRank > userRank) continue;

        workoutExercises.add(WorkoutExercise(
          exerciseId: found.id,
          exerciseName: found.name,
          muscleGroup: found.muscleGroup,
          sets: sets.toInt(),
          targetReps: reps.toInt(),
        ));
      }

      if (workoutExercises.isEmpty) continue;

      final muscles =
          (dayMap['muscleGroups'] as List? ?? []).whereType<String>().toList();
      final template = WorkoutTemplate(
        id: workoutProvider.generateId(),
        name: '${plan['planName']} — $dayName',
        description: 'AI Generated',
        muscleGroups: muscles.isNotEmpty ? muscles : ['Mixed'],
        exercises: workoutExercises,
        createdAt: DateTime.now(),
        isAiGenerated: true,
      );

      await workoutProvider.addTemplate(template);
      templatesAdded++;
    }

    if (templatesAdded == 0) {
      throw Exception('No valid workouts could be created from the plan');
    }
  }

  UserProfile _profileOrFallback(UserProfile? profile) {
    if (profile != null) return profile;
    return UserProfile(
      nickname: 'Athlete',
      age: 25,
      weightKg: 75,
      heightCm: 175,
      goal: 'Build Muscle',
      fitnessLevel: 'Beginner',
      availableEquipment: const ['Gym'],
      workoutsPerWeek: 3,
    );
  }
}
