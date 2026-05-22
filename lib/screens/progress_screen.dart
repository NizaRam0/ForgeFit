import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../providers/workout_provider.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final logs = List<WorkoutLog>.from(workoutProvider.logs)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        title: const Text('Progress'),
        backgroundColor: AppTheme.bg(context),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Summary'),
                Tab(text: 'History'),
                Tab(text: 'Records'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SummaryTab(workoutProvider: workoutProvider),
                  _HistoryTab(logs: logs),
                  _RecordsTab(logs: logs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final WorkoutProvider workoutProvider;

  const _SummaryTab({required this.workoutProvider});

  @override
  Widget build(BuildContext context) {
    final muscleVolume = workoutProvider.getMuscleVolumeProgress();
    final entries = muscleVolume.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.fold(0.0, (sum, entry) => sum + entry.value);
        final bTotal = b.value.fold(0.0, (sum, entry) => sum + entry.value);
        return bTotal.compareTo(aTotal);
      });
    final maxVolume = entries.isEmpty
        ? 0.0
        : entries
            .map((e) => e.value.fold(0.0, (sum, item) => sum + item.value))
            .reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: [
              _buildRow(context, 'Workouts This Week',
                  workoutProvider.workoutsThisWeek.toString()),
              const SizedBox(height: 10),
              _buildRow(context, 'Volume This Week',
                  workoutProvider.volumeThisWeek.toStringAsFixed(1)),
              const SizedBox(height: 10),
              _buildRow(context, 'Current Streak',
                  '${workoutProvider.currentStreak} days'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Volume by Muscle Group',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onText(context),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(
            children: entries.isEmpty
                ? [
                    Text(
                      'No volume data yet.',
                      style: TextStyle(color: AppTheme.onSubtext(context)),
                    ),
                  ]
                : entries.map((entry) {
                    final total =
                        entry.value.fold(0.0, (sum, item) => sum + item.value);
                    final ratio = maxVolume > 0 ? total / maxVolume : 0.0;
                    final muscleColor = Color(
                        MuscleGroupColors.colors[entry.key] ??
                            AppTheme.primary.value);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: AppTheme.onText(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppTheme.elevated(context),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: ratio,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: muscleColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 64,
                            child: Text(
                              total.toStringAsFixed(0),
                              textAlign: TextAlign.right,
                              style:
                                  TextStyle(color: AppTheme.onSubtext(context)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: AppTheme.onSubtext(context))),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.onText(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<WorkoutLog> logs;

  const _HistoryTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<WorkoutLog>>{};
    for (final log in logs) {
      final weekStart = DateTime(log.date.year, log.date.month, log.date.day)
          .subtract(Duration(days: log.date.weekday - 1));
      grouped.putIfAbsent(weekStart, () => []).add(log);
    }

    final sortedWeeks = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedWeeks.isEmpty
          ? [
              Text(
                'No workout history yet.',
                style: TextStyle(color: AppTheme.onSubtext(context)),
              ),
            ]
          : sortedWeeks.map((weekStart) {
              final weekLogs = grouped[weekStart]!
                ..sort((a, b) => b.date.compareTo(a.date));
              final weekLabel =
                  '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weekLabel,
                        style: TextStyle(
                          color: AppTheme.onText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...weekLogs.map((log) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            collapsedIconColor: AppTheme.onSubtext(context),
                            iconColor: AppTheme.primary,
                            title: Text(
                              log.templateName,
                              style: TextStyle(
                                color: AppTheme.onText(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${DateFormat('EEE, MMM d').format(log.date)} • ${log.duration.inMinutes} min • ${log.totalVolume.toStringAsFixed(0)} volume',
                                style: TextStyle(
                                  color: AppTheme.onSubtext(context),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: log.muscleGroups.map((muscle) {
                                  final muscleColor = Color(
                                      MuscleGroupColors.colors[muscle] ??
                                          AppTheme.primary.value);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: muscleColor.withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(muscle,
                                        style: TextStyle(
                                            color: muscleColor, fontSize: 12)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              ...log.exercises.map((exercise) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exercise.exerciseName,
                                          style: TextStyle(
                                            color: AppTheme.onText(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${exercise.volume.toStringAsFixed(0)} vol',
                                        style: TextStyle(
                                          color: AppTheme.onSubtext(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final List<WorkoutLog> logs;

  const _RecordsTab({required this.logs});

  @override
  Widget build(BuildContext context) {
    final records = <String, _RecordEntry>{};

    for (final log in logs) {
      for (final exercise in log.exercises) {
        final current = records[exercise.exerciseId];
        final maxWeight = exercise.maxWeight;
        if (current == null || maxWeight > current.maxWeight) {
          records[exercise.exerciseId] = _RecordEntry(
            exerciseId: exercise.exerciseId,
            name: exercise.exerciseName,
            muscleGroup: exercise.muscleGroup,
            maxWeight: maxWeight,
          );
        }
      }
    }

    final ranked = records.values.toList()
      ..sort((a, b) => b.maxWeight.compareTo(a.maxWeight));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: ranked.isEmpty
          ? [
              Text(
                'No records available yet.',
                style: TextStyle(color: AppTheme.onSubtext(context)),
              ),
            ]
          : ranked.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final muscleColor = Color(
                  MuscleGroupColors.colors[record.muscleGroup] ??
                      AppTheme.primary.value);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Icon(
                          index < 3 ? Icons.emoji_events : Icons.fitness_center,
                          color: index == 0
                              ? Colors.amber
                              : index == 1
                                  ? Colors.blueGrey.shade300
                                  : index == 2
                                      ? Colors.brown.shade300
                                      : AppTheme.onSubtext(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.name,
                              style: TextStyle(
                                color: AppTheme.onText(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(record.muscleGroup,
                                style: TextStyle(color: muscleColor)),
                          ],
                        ),
                      ),
                      Text(
                        record.maxWeight.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppTheme.onText(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }
}

class _RecordEntry {
  final String exerciseId;
  final String name;
  final String muscleGroup;
  final double maxWeight;

  const _RecordEntry({
    required this.exerciseId,
    required this.name,
    required this.muscleGroup,
    required this.maxWeight,
  });
}
