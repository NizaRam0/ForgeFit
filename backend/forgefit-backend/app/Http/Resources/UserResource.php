<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'nickname' => $this->nickname,
            'email' => $this->email,
            'gender' => $this->gender,
            'age' => $this->age,
            'weight_kg' => $this->weight_kg,
            'height_cm' => $this->height_cm,
            'goal' => $this->goal,
            'fitness_level' => $this->fitness_level,
            'available_equipment' => $this->available_equipment,
            'workouts_per_week' => $this->workouts_per_week,
            'profile_complete' => (bool) $this->profile_complete,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
