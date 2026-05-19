import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final muscleColor = Color(MuscleGroupColors.colors[exercise.muscleGroup] ?? 0xFFFF6B35);
    final progressData = context.watch<WorkoutProvider>().getExerciseProgress(exercise.id);
    final lastWeight = context.watch<WorkoutProvider>().getLastWeight(exercise.id);
    final suggestedWeight = context.watch<WorkoutProvider>().getSuggestedWeight(exercise.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(exercise.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [muscleColor.withOpacity(0.3), AppTheme.surface],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.fitness_center, size: 80, color: muscleColor.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tags
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTag(exercise.muscleGroup, muscleColor),
                    _buildTag(exercise.difficulty, AppTheme.warning),
                    _buildTag(exercise.equipment, AppTheme.accent),
                  ],
                ),
                if (exercise.secondaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Also works: ${exercise.secondaryMuscles}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 20),

                // Progressive overload info
                if (lastWeight != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Progressive Overload', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                              const SizedBox(height: 4),
                              Text('Last: ${lastWeight}kg  →  Suggested: ${suggestedWeight?.toStringAsFixed(1)}kg',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Instructions
                _buildSection(
                  'How to Perform',
                  Icons.play_circle_outline,
                  AppTheme.accent,
                  exercise.instructions,
                ),
                const SizedBox(height: 16),

                // Form Tips
                _buildSection(
                  'Form Tips',
                  Icons.tips_and_updates_outlined,
                  AppTheme.warning,
                  exercise.formTips,
                ),
                const SizedBox(height: 20),

                // Progress chart (if data exists)
                if (progressData.isNotEmpty) ...[
                  const Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _buildSimpleProgressChart(progressData),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(
            height: 1.6,
            color: AppTheme.textPrimary,
            fontSize: 14,
          )),
        ],
      ),
    );
  }

  Widget _buildSimpleProgressChart(List<MapEntry<DateTime, double>> data) {
    if (data.isEmpty) return const SizedBox();
    final maxW = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.take(12).map((entry) {
          final ratio = maxW > 0 ? entry.value / maxW : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: 80 * ratio,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}