<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class SetEntryResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'weight' => $this->weight,
            'reps' => $this->reps,
            'completed' => (bool)$this->completed,
            'sort_order' => $this->sort_order,
        ];
    }
}
