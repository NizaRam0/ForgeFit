<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class WorkoutLogResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'template_id' => $this->template_id,
            'template_name' => $this->template_name,
            'date' => $this->date,
            'duration_seconds' => $this->duration_seconds,
            'notes' => $this->notes,
            'muscle_groups' => $this->muscle_groups,
            'exercises' => $this->whenLoaded('logExercises') ? $this->logExercises->map(function($le){
                return [
                    'id' => $le->id,
                    'exercise_id' => $le->exercise_id,
                    'exercise_name' => $le->exercise_name,
                    'muscle_group' => $le->muscle_group,
                    'sort_order' => $le->sort_order,
                    'sets' => $le->setEntries->map(function($set){
                        return new SetEntryResource($set);
                    })
                ];
            }) : [],
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
