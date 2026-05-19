import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscleColor = Color(MuscleGroupColors.colors[exercise.muscleGroup] ??
        AppTheme.primary.value);
    final difficultyColor = switch (exercise.difficulty) {
      'Beginner' => AppTheme.success,
      'Intermediate' => AppTheme.warning,
      'Advanced' => AppTheme.error,
      _ => AppTheme.textSecondary,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            // Icon / placeholder image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: muscleColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.fitness_center,
                color: muscleColor,
              ),
            ),

            const SizedBox(width: 12),

            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        exercise.muscleGroup,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          exercise.difficulty,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: difficultyColor,
                          ),
                        ),
                      ),
                      if (exercise.isCustom)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Equipment: ${exercise.equipment}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
