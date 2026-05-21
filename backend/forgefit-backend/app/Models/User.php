<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name','nickname','email','password','gender','age','weight_kg','height_cm','goal','fitness_level','available_equipment','workouts_per_week','profile_complete'
    ];

    protected $casts = [
        'available_equipment' => 'array',
        'profile_complete' => 'boolean',
        'workouts_per_week' => 'integer',
        'age' => 'integer',
        'weight_kg' => 'float',
        'height_cm' => 'float',
    ];

    protected $hidden = ['password','remember_token'];

    public function getAvailableEquipmentAttribute($value)
    {
        if (is_array($value)) {
            return $value;
        }

        if (is_string($value) && $value !== '') {
            $decoded = json_decode($value, true);
            if (json_last_error() === JSON_ERROR_NONE && is_array($decoded)) {
                return $decoded;
            }
        }

        return $value;
    }

    public function workoutTemplates()
    {
        return $this->hasMany(WorkoutTemplate::class);
    }

    public function workoutLogs()
    {
        return $this->hasMany(WorkoutLog::class);
    }

    public function exercises()
    {
        return $this->hasMany(Exercise::class);
    }
}
