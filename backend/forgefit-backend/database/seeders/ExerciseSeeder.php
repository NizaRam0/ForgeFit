<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;

class ExerciseSeeder extends Seeder
{
    public function run(): void
    {
        $now = Carbon::now();
        $items = [];

        $groups = [
            'Chest' => [
                ['Bench Press','Barbell bench press instructions...','Keep shoulders retracted...'],
                ['Incline Dumbbell Press','Incline DB press instructions...','Keep elbows 45deg...'],
                ['Chest Fly','Machine fly instructions...','Avoid overstretch...']
            ],
            'Back' => [
                ['Pull Up','Pull up instructions...','Full range of motion...'],
                ['Bent Over Row','Row instructions...','Neutral spine...'],
                ['Lat Pulldown','Lat pulldown instructions...','Lead with elbows...']
            ],
            'Legs' => [
                ['Back Squat','Squat instructions...','Knees out...'],
                ['Romanian Deadlift','RDL instructions...','Hinge at hips...'],
                ['Leg Press','Leg press instructions...','Do not lock knees...']
            ],
            'Shoulders' => [
                ['Overhead Press','OHP instructions...','Brace core...'],
                ['Lateral Raise','Lat raise instructions...','Slight elbow bend...'],
                ['Rear Delt Fly','Rear delt instructions...','Control reps...']
            ],
            'Biceps' => [
                ['Barbell Curl','Curl instructions...','Full control...'],
                ['Hammer Curl','Hammer curl instructions...','Neutral grip...'],
                ['Preacher Curl','Preacher curl instructions...','Avoid shoulder swing...']
            ],
            'Triceps' => [
                ['Triceps Pushdown','Pushdown instructions...','Keep elbows tucked...'],
                ['Skullcrusher','Skullcrusher instructions...','Control the negative...'],
                ['Overhead Extension','OH ext instructions...','Full stretch...']
            ],
            'Glutes' => [
                ['Hip Thrust','Hip thrust instructions...','Drive through heels...'],
                ['Glute Bridge','Bridge instructions...','Squeeze glutes...'],
                ['Bulgarian Split Squat','BSS instructions...','Keep torso upright...']
            ],
            'Core' => [
                ['Plank','Plank instructions...','Keep neutral spine...'],
                ['Hanging Leg Raise','Leg raise instructions...','Control swing...'],
                ['Russian Twist','Twist instructions...','Rotate through torso...']
            ],
            'Calves' => [
                ['Standing Calf Raise','Calf raise instructions...','Full ROM...'],
                ['Seated Calf Raise','Seated instructions...','Pause at top...'],
                ['Donkey Calf Raise','Donkey instructions...','Slow reps...']
            ],
        ];

        foreach ($groups as $group => $exs) {
            foreach ($exs as $ex) {
                $items[] = [
                    'id' => (string) Str::uuid(),
                    'name' => $ex[0],
                    'muscle_group' => $group,
                    'secondary_muscles' => null,
                    'difficulty' => 'Intermediate',
                    'equipment' => 'Gym',
                    'instructions' => $ex[1],
                    'form_tips' => $ex[2],
                    'gif_url' => null,
                    'is_custom' => false,
                    'user_id' => null,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        DB::table('exercises')->upsert(
            $items,
            ['id'],
            [
                'name',
                'muscle_group',
                'secondary_muscles',
                'difficulty',
                'equipment',
                'instructions',
                'form_tips',
                'gif_url',
                'is_custom',
                'user_id',
                'created_at',
                'updated_at',
            ]
        );
    }
}
