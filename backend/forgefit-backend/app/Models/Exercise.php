<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class Exercise extends Model
{
    use HasFactory, HasUuids;

    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = [
        'id','name','muscle_group','secondary_muscles','difficulty','equipment','instructions','form_tips','gif_url','is_custom','user_id'
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
