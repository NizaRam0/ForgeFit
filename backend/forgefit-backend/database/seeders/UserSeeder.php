<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Carbon\Carbon;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // -----------------------------------------------------------------
        // 1. Test user account (complete profile, ready to use immediately)
        // -----------------------------------------------------------------
        $existing = DB::table('users')->where('email', 'test@gmail.com')->first();

        if ($existing) {
            // Wipe previous seed data so we can re-seed cleanly
            DB::table('workout_logs')->where('user_id', $existing->id)->delete();
            DB::table('workout_templates')->where('user_id', $existing->id)->delete();
            $userId = $existing->id;
        } else {
            $userId = DB::table('users')->insertGetId([
                'name'                => 'Nizar Ramadan',
                'nickname'            => 'NizaRam0',
                'email'               => 'test@gmail.com',
                'password'            => Hash::make('password'),
                'gender'              => 'male',
                'age'                 => 22,
                'weight_kg'           => 78.50,
                'height_cm'           => 179.00,
                'goal'                => 'Build Muscle',
                'fitness_level'       => 'Intermediate',
                'available_equipment' => json_encode(['barbell', 'dumbbells', 'bench', 'pull-up bar', 'cables']),
                'workouts_per_week'   => 4,
                'profile_complete'    => true,
                'created_at'          => now(),
                'updated_at'          => now(),
            ]);
        }

        // -----------------------------------------------------------------
        // 2. Pull seeded exercise IDs by name for easy reference
        // -----------------------------------------------------------------
        $ex = DB::table('exercises')->whereNull('user_id')->pluck('id', 'name');

        // Exercise groups used in workout plans below
        $pushExercises  = ['Bench Press', 'Overhead Press', 'Triceps Pushdown', 'Lateral Raise', 'Skullcrusher'];
        $pullExercises  = ['Pull Up', 'Bent Over Row', 'Barbell Curl', 'Lat Pulldown', 'Hammer Curl'];
        $legExercises   = ['Back Squat', 'Romanian Deadlift', 'Leg Press', 'Bulgarian Split Squat', 'Hip Thrust'];
        $upperExercises = ['Bench Press', 'Overhead Press', 'Pull Up', 'Bent Over Row', 'Barbell Curl'];

        $plans = [
            ['Push Day A', $pushExercises,  ['Chest', 'Shoulders', 'Triceps']],
            ['Pull Day A', $pullExercises,  ['Back', 'Biceps']],
            ['Leg Day A',  $legExercises,   ['Legs', 'Glutes']],
            ['Upper Body', $upperExercises, ['Chest', 'Back', 'Shoulders', 'Biceps']],
        ];

        // -----------------------------------------------------------------
        // 3. Seed workout templates
        // -----------------------------------------------------------------
        $templateIds = [];
        foreach ($plans as [$planName, $exerciseNames, $muscleGroups]) {
            $templateId = (string) Str::uuid();
            DB::table('workout_templates')->insert([
                'id'              => $templateId,
                'user_id'         => $userId,
                'name'            => $planName,
                'description'     => null,
                'muscle_groups'   => json_encode($muscleGroups),
                'is_ai_generated' => false,
                'created_at'      => now(),
                'updated_at'      => now(),
            ]);
            $templateIds[$planName] = $templateId;

            // Template exercises
            foreach ($exerciseNames as $sortOrder => $exName) {
                $exId = $ex[$exName] ?? null;
                if (!$exId) continue; // skip if exercise wasn't seeded

                DB::table('workout_template_exercises')->insert([
                    'template_id' => $templateId,
                    'exercise_id' => $exId,
                    'sets'        => 4,
                    'target_reps' => 10,
                    'sort_order'  => $sortOrder,
                    'created_at'  => now(),
                    'updated_at'  => now(),
                ]);
            }
        }

        // -----------------------------------------------------------------
        // 4. Seed 6 weeks of workout logs (4 sessions/week)
        // -----------------------------------------------------------------
        $rotatingPlans = array_keys($templateIds);
        $planIndex = 0;
        $now = Carbon::now();

        // Go back 6 weeks, 4 workouts per week
        for ($week = 6; $week >= 0; $week--) {
            $weekStart = $now->copy()->subWeeks($week)->startOfWeek();

            // 4 workout days: Mon, Tue, Thu, Fri
            $workoutDays = [0, 1, 3, 4]; // offsets from Monday

            foreach ($workoutDays as $dayOffset) {
                $workoutDate = $weekStart->copy()->addDays($dayOffset);

                // Skip future dates
                if ($workoutDate->isAfter($now)) {
                    continue;
                }

                $planName     = $rotatingPlans[$planIndex % count($rotatingPlans)];
                $planIndex++;
                $templateId   = $templateIds[$planName];
                $planData     = $plans[array_search($planName, array_column($plans, 0))];
                $exerciseNames = $planData[1];
                $muscleGroups  = $planData[2];

                // Slightly vary duration & volume to look realistic
                $durationSeconds = rand(2700, 4500); // 45–75 min
                $logId = (string) Str::uuid();

                DB::table('workout_logs')->insert([
                    'id'               => $logId,
                    'user_id'          => $userId,
                    'template_id'      => $templateId,
                    'template_name'    => $planName,
                    'date'             => $workoutDate->toDateTimeString(),
                    'duration_seconds' => $durationSeconds,
                    'notes'            => null,
                    'muscle_groups'    => json_encode($muscleGroups),
                    'created_at'       => $workoutDate->toDateTimeString(),
                    'updated_at'       => $workoutDate->toDateTimeString(),
                ]);

                // Log exercises + sets
                foreach ($exerciseNames as $sortOrder => $exName) {
                    $logExId = DB::table('workout_log_exercises')->insertGetId([
                        'log_id'        => $logId,
                        'exercise_id'   => $ex[$exName] ?? null,
                        'exercise_name' => $exName,
                        'muscle_group'  => DB::table('exercises')->where('name', $exName)->value('muscle_group') ?? 'Other',
                        'sort_order'    => $sortOrder,
                        'created_at'    => $workoutDate->toDateTimeString(),
                        'updated_at'    => $workoutDate->toDateTimeString(),
                    ]);

                    // 4 sets per exercise — weight increases slightly over weeks
                    $weeklyProgression = (6 - $week) * 2.5; // adds ~2.5 kg per week
                    $baseWeights = [
                        'Bench Press'          => 80,
                        'Overhead Press'       => 55,
                        'Triceps Pushdown'     => 35,
                        'Lateral Raise'        => 14,
                        'Skullcrusher'         => 30,
                        'Pull Up'              => 0,   // bodyweight
                        'Bent Over Row'        => 70,
                        'Barbell Curl'         => 40,
                        'Lat Pulldown'         => 60,
                        'Hammer Curl'          => 20,
                        'Back Squat'           => 100,
                        'Romanian Deadlift'    => 80,
                        'Leg Press'            => 140,
                        'Bulgarian Split Squat'=> 30,
                        'Hip Thrust'           => 100,
                    ];
                    $baseWeight = ($baseWeights[$exName] ?? 40) + $weeklyProgression;

                    for ($set = 1; $set <= 4; $set++) {
                        DB::table('set_entries')->insert([
                            'log_exercise_id' => $logExId,
                            'weight'          => $baseWeight + rand(-2, 2),
                            'reps'            => rand(8, 12),
                            'completed'       => true,
                            'sort_order'      => $set - 1,
                            'created_at'      => $workoutDate->toDateTimeString(),
                            'updated_at'      => $workoutDate->toDateTimeString(),
                        ]);
                    }
                }
            }
        }
    }
}
