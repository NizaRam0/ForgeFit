<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ExerciseResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'muscle_group' => $this->muscle_group,
            'secondary_muscles' => $this->secondary_muscles,
            'difficulty' => $this->difficulty,
            'equipment' => $this->equipment,
            'instructions' => $this->instructions,
            'form_tips' => $this->form_tips,
            'gif_url' => $this->gif_url,
            'is_custom' => (bool) $this->is_custom,
            'user_id' => $this->user_id,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
