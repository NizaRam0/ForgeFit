<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class WorkoutTemplateResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'name' => $this->name,
            'description' => $this->description,
            'muscle_groups' => $this->muscle_groups,
            'is_ai_generated' => (bool)$this->is_ai_generated,
            'exercises' => $this->whenLoaded('templateExercises') ? $this->templateExercises->filter(function($te){
                return $te->exercise !== null;
            })->map(function($te){
                return [
                    'id' => $te->id,
                    'exercise' => new ExerciseResource($te->exercise),
                    'sets' => $te->sets,
                    'target_reps' => $te->target_reps,
                    'sort_order' => $te->sort_order,
                ];
            })->values() : [],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
