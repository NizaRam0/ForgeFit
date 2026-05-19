<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class WorkoutTemplateExercise extends Model
{
    use HasFactory;

    protected $fillable = ['template_id','exercise_id','sets','target_reps','sort_order'];

    public function template()
    {
        return $this->belongsTo(WorkoutTemplate::class, 'template_id');
    }

    public function exercise()
    {
        return $this->belongsTo(Exercise::class);
    }
}
