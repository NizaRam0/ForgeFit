<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_template_exercises', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->char('template_id', 36);
            $table->char('exercise_id', 36);
            $table->unsignedTinyInteger('sets');
            $table->unsignedTinyInteger('target_reps');
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('template_id')->references('id')->on('workout_templates')->onDelete('cascade');
            $table->foreign('exercise_id')->references('id')->on('exercises')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_template_exercises');
    }
};
