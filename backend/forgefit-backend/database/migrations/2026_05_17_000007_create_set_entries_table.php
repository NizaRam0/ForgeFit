<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('set_entries', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('log_exercise_id');
            $table->decimal('weight', 6, 2);
            $table->unsignedSmallInteger('reps');
            $table->boolean('completed')->default(false);
            $table->unsignedTinyInteger('sort_order')->default(0);
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('log_exercise_id')->references('id')->on('workout_log_exercises')->onDelete('cascade');
            $table->index('log_exercise_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('set_entries');
    }
};
