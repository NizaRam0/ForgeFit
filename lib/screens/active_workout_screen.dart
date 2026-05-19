import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/timer_provider.dart';
import '../../models/workout.dart';
import '../../utils/app_theme.dart';
import '../../widgets/rest_timer_widget.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late Stopwatch _stopwatch;
  late Timer _clockTimer;
  final _notesController = TextEditingController();
  int _expandedExercise = 0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _clockTimer.cancel();
    _notesController.dispose();
    super.dispose();
  }

  String get _elapsed {
    final d = _stopwatch.elapsed;
    return '${d.inHours.toString().padLeft(2, '0')}:'
        '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _finishWorkout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great work! Save this session?'),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Going', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save & Finish')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<WorkoutProvider>().finishWorkout(
        _stopwatch.elapsed,
        _notesController.text,
      );
    }
  }

  void _cancelWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Cancel Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue', style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WorkoutProvider>().cancelWorkout();
            },
            child: const Text('Cancel Workout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.watch<WorkoutProvider>();
    final activeWorkout = workoutProvider.activeWorkout;

    // Guard: workout was just finished/cancelled; HomeScreen will replace us.
    if (activeWorkout == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final timerProvider = context.watch<TimerProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.error),
          onPressed: _cancelWorkout,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activeWorkout.templateName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(_elapsed, style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: _finishWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Finish'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Rest Timer (shows when running)
          if (timerProvider.state != TimerState.idle) const RestTimerWidget(),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: activeWorkout.exercises.length,
              itemBuilder: (ctx, i) {
                final exercise = activeWorkout.exercises[i];
                final isExpanded = _expandedExercise == i;
                final completedSets = exercise.loggedSets.length;
                final allDone = completedSets >= exercise.sets;

                return GestureDetector(
                  onTap: () => setState(() => _expandedExercise = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: allDone
                            ? AppTheme.success.withOpacity(0.5)
                            : isExpanded
                                ? AppTheme.primary.withOpacity(0.5)
                                : Colors.white.withOpacity(0.06),
                        width: isExpanded || allDone ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: allDone ? AppTheme.success.withOpacity(0.2) : AppTheme.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: allDone
                                      ? const Icon(Icons.check, color: AppTheme.success, size: 18)
                                      : Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(exercise.exerciseName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                    Text(
                                      '$completedSets/${exercise.sets} sets • ${exercise.targetReps} reps',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Last weight / suggested weight
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (exercise.lastWeight != null)
                                    Text('Last: ${exercise.lastWeight}kg',
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  _buildSetProgressDots(exercise),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Expanded: set logging
                        if (isExpanded) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Column headers
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 36, child: Text('Set', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                                      SizedBox(width: 16),
                                      Expanded(child: Text('kg', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Reps', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center)),
                                      SizedBox(width: 40),
                                    ],
                                  ),
                                ),

                                // Logged sets
                                ...List.generate(exercise.loggedSets.length, (si) {
                                  final set = exercise.loggedSets[si];
                                  return _LoggedSetRow(
                                    setNumber: si + 1,
                                    setEntry: set,
                                    onDelete: () => workoutProvider.removeSet(i, si),
                                  );
                                }),

                                // Log new set row
                                _LogNewSetRow(
                                  setNumber: exercise.loggedSets.length + 1,
                                  suggestedWeight: exercise.lastWeight,
                                  targetReps: exercise.targetReps,
                                  onLog: (weight, reps) {
                                    workoutProvider.logSet(i, SetEntry(weight: weight, reps: reps, completed: true));
                                    // Auto-start rest timer
                                    context.read<TimerProvider>().startTimer(90);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildSetProgressDots(WorkoutExercise exercise) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(exercise.sets, (i) {
        return Container(
          width: 8, height: 8,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < exercise.loggedSets.length
                ? AppTheme.success
                : AppTheme.surfaceElevated,
          ),
        );
      }),
    );
  }
}

// ─── Logged set row (read-only with delete) ─────────────────────────────────
class _LoggedSetRow extends StatelessWidget {
  final int setNumber;
  final SetEntry setEntry;
  final VoidCallback onDelete;

  const _LoggedSetRow({
    required this.setNumber,
    required this.setEntry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Text('$setNumber', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.w700, fontSize: 12))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Center(child: Text('${setEntry.weight}', style: const TextStyle(fontWeight: FontWeight.w600)))),
          const SizedBox(width: 8),
          Expanded(child: Center(child: Text('${setEntry.reps}', style: const TextStyle(fontWeight: FontWeight.w600)))),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New set input row ───────────────────────────────────────────────────────
class _LogNewSetRow extends StatefulWidget {
  final int setNumber;
  final double? suggestedWeight;
  final int targetReps;
  final Function(double weight, int reps) onLog;

  const _LogNewSetRow({
    required this.setNumber,
    required this.suggestedWeight,
    required this.targetReps,
    required this.onLog,
  });

  @override
  State<_LogNewSetRow> createState() => _LogNewSetRowState();
}

class _LogNewSetRowState extends State<_LogNewSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.suggestedWeight != null ? widget.suggestedWeight!.toStringAsFixed(1) : '',
    );
    _repsController = TextEditingController(text: '${widget.targetReps}');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Text('${widget.setNumber}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'kg',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                fillColor: AppTheme.surfaceElevated.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'reps',
                hintStyle: const TextStyle(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                fillColor: AppTheme.surfaceElevated.withOpacity(0.5),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: GestureDetector(
              onTap: () {
                final weight = double.tryParse(_weightController.text) ?? 0;
                final reps = int.tryParse(_repsController.text) ?? 0;
                if (weight > 0 && reps > 0) {
                  widget.onLog(weight, reps);
                }
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}