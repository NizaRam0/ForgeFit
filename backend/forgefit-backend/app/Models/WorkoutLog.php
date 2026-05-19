<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class WorkoutLog extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['id','user_id','template_id','template_name','date','duration_seconds','notes','muscle_groups'];

    protected $casts = ['muscle_groups' => 'array','date'=>'datetime'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function logExercises()
    {
        return $this->hasMany(WorkoutLogExercise::class, 'log_id');
    }

    public function template()
    {
        return $this->belongsTo(WorkoutTemplate::class, 'template_id');
    }
}
