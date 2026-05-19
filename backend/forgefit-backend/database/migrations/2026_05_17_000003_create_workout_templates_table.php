<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_templates', function (Blueprint $table) {
            $table->char('id', 36)->primary();
            $table->unsignedBigInteger('user_id');
            $table->string('name');
            $table->string('description')->nullable();
            $table->json('muscle_groups');
            $table->boolean('is_ai_generated')->default(false);
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_templates');
    }
};
