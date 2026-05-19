<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class WorkoutLogExercise extends Model
{
    use HasFactory;

    protected $fillable = ['log_id','exercise_id','exercise_name','muscle_group','sort_order'];

    public function log()
    {
        return $this->belongsTo(WorkoutLog::class, 'log_id');
    }

    public function setEntries()
    {
        return $this->hasMany(SetEntry::class, 'log_exercise_id');
    }

    public function exercise()
    {
        return $this->belongsTo(Exercise::class);
    }
}
