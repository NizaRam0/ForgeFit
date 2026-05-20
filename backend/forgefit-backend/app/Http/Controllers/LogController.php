<?php

namespace App\Http\Controllers;

use App\Models\WorkoutLog;
use App\Models\WorkoutLogExercise;
use App\Models\SetEntry;
use App\Http\Resources\WorkoutLogResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;

class LogController extends Controller
{
    public function index(Request $request)
    {
        $logs = WorkoutLog::where('user_id', $request->user()->id)
            ->with('logExercises.setEntries')
            ->orderBy('date','desc')
            ->get();

        return response()->json(['data' => WorkoutLogResource::collection($logs)]);
    }

    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'template_id' => 'sometimes|nullable|string',
            'template_name' => 'required|string',
            'date' => 'required|date',
            'duration_seconds' => 'required|integer|min:0',
            'notes' => 'sometimes|string|nullable',
            'muscle_groups' => 'required|array',
            'exercises' => 'required|array|min:1',
            'exercises.*.exercise_id' => 'sometimes|nullable|string',
            'exercises.*.exercise_name' => 'required|string',
            'exercises.*.muscle_group' => 'required|string',
            'exercises.*.sets' => 'required|array|min:1',
            'exercises.*.sets.*.weight' => 'required|numeric',
            'exercises.*.sets.*.reps' => 'required|integer',
            'exercises.*.sets.*.completed' => 'sometimes|boolean'
        ]);

        if ($v->fails()) return response()->json(['message'=>'Validation failed','errors'=>$v->errors()],422);

        $logId = (string) Str::uuid();

        DB::transaction(function() use ($request, $logId) {
            $log = WorkoutLog::create([
                'id' => $logId,
                'user_id' => $request->user()->id,
                'template_id' => $request->template_id,
                'template_name' => $request->template_name,
                'date' => $request->date,
                'duration_seconds' => $request->duration_seconds,
                'notes' => $request->notes,
                'muscle_groups' => $request->muscle_groups,
            ]);

            foreach ($request->exercises as $ex) {
                $le = WorkoutLogExercise::create([
                    'log_id' => $logId,
                    'exercise_id' => $ex['exercise_id'] ?? null,
                    'exercise_name' => $ex['exercise_name'],
                    'muscle_group' => $ex['muscle_group'],
                    'sort_order' => $ex['sort_order'] ?? 0,
                ]);

                foreach ($ex['sets'] as $idx => $s) {
                    SetEntry::create([
                        'log_exercise_id' => $le->id,
                        'weight' => $s['weight'],
                        'reps' => $s['reps'],
                        'completed' => $s['completed'] ?? false,
                        'sort_order' => $s['sort_order'] ?? $idx,
                    ]);
                }
            }
        });

        $log = WorkoutLog::with('logExercises.setEntries')->find($logId);
        return response()->json(['data'=>['log'=>new WorkoutLogResource($log)], 'message'=>'Workout logged'], 201);
    }

    public function destroy(Request $request, $id)
    {
        $log = WorkoutLog::findOrFail($id);
        if ($log->user_id !== $request->user()->id) return response()->json(['message'=>'Forbidden'],403);
        $log->delete();
        return response()->json(['message'=>'Log deleted']);
    }

    public function stats(Request $request)
    {
        $userId = $request->user()->id;

        // week range (Monday->Sunday)
        $startOfWeek = now()->startOfWeek();
        $endOfWeek = now()->endOfWeek();

        $workoutsThisWeek = WorkoutLog::where('user_id',$userId)
            ->whereBetween('date', [$startOfWeek, $endOfWeek])->count();

        $volumeThisWeek = DB::table('workout_logs')
            ->join('workout_log_exercises','workout_log_exercises.log_id','workout_logs.id')
            ->join('set_entries','set_entries.log_exercise_id','workout_log_exercises.id')
            ->where('workout_logs.user_id',$userId)
            ->whereBetween('workout_logs.date', [$startOfWeek, $endOfWeek])
            ->selectRaw('SUM(set_entries.weight * set_entries.reps) as volume')
            ->value('volume');

        // current streak - start cursor at today, but if today has no workout start at yesterday
        $rawDates = WorkoutLog::where('user_id',$userId)
            ->selectRaw('DATE(date) as day')
            ->distinct()
            ->pluck('day')
            ->toArray();
        $dateSet = [];
        foreach ($rawDates as $d) {
            $dateSet[date('Y-m-d', strtotime($d))] = true;
        }

        $streak = 0;
        $cursor = now()->startOfDay();
        if (!isset($dateSet[$cursor->toDateString()])) {
            $cursor = $cursor->subDay();
        }
        while (isset($dateSet[$cursor->toDateString()])) {
            $streak++;
            $cursor = $cursor->subDay();
        }

        $totalWorkouts = WorkoutLog::where('user_id',$userId)->count();

        return response()->json(['data'=>[
            'workouts_this_week' => (int)$workoutsThisWeek,
            'volume_this_week' => (float) ($volumeThisWeek ?? 0),
            'current_streak' => (int)$streak,
            'total_workouts' => (int)$totalWorkouts,
        ]]);
    }

    public function exerciseProgress(Request $request, $exerciseId)
    {
        $userId = $request->user()->id;

        $rows = DB::table('workout_logs')
            ->join('workout_log_exercises','workout_log_exercises.log_id','workout_logs.id')
            ->join('set_entries','set_entries.log_exercise_id','workout_log_exercises.id')
            ->where('workout_logs.user_id',$userId)
            ->where('workout_log_exercises.exercise_id',$exerciseId)
            ->selectRaw('DATE(workout_logs.date) as date, MAX(set_entries.weight) as max_weight')
            ->groupByRaw('DATE(workout_logs.date)')
            ->orderBy('date','asc')
            ->get();

        return response()->json(['data' => $rows]);
    }
}
