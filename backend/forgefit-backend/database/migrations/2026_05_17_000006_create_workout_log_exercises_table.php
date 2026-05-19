<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_log_exercises', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->char('log_id', 36);
            $table->char('exercise_id', 36)->nullable();
            $table->string('exercise_name');
            $table->string('muscle_group');
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('log_id')->references('id')->on('workout_logs')->onDelete('cascade');
            $table->foreign('exercise_id')->references('id')->on('exercises')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_log_exercises');
    }
};
