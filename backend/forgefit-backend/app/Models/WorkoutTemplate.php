<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class WorkoutTemplate extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['id','user_id','name','description','muscle_groups','is_ai_generated'];

    protected $casts = ['muscle_groups' => 'array'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function templateExercises()
    {
        return $this->hasMany(WorkoutTemplateExercise::class, 'template_id');
    }
}
