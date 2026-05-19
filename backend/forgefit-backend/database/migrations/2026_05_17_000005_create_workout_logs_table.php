<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_logs', function (Blueprint $table) {
            $table->char('id', 36)->primary();
            $table->unsignedBigInteger('user_id');
            $table->char('template_id', 36)->nullable();
            $table->string('template_name');
            $table->dateTime('date')->index();
            $table->unsignedInteger('duration_seconds');
            $table->text('notes')->nullable();
            $table->json('muscle_groups');
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('template_id')->references('id')->on('workout_templates')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_logs');
    }
};
