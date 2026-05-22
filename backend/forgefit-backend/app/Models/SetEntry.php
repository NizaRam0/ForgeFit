<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class SetEntry extends Model
{
    use HasFactory;

    protected $fillable = ['log_exercise_id','weight','reps','completed','sort_order'];

    protected $casts = ['weight' => 'float', 'reps' => 'integer', 'completed' => 'boolean'];

    public function logExercise()
    {
        return $this->belongsTo(WorkoutLogExercise::class, 'log_exercise_id');
    }
}
