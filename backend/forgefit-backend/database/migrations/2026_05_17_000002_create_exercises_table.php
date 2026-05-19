<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercises', function (Blueprint $table) {
            $table->char('id', 36)->primary();
            $table->string('name');
            $table->string('muscle_group')->index();
            $table->string('secondary_muscles')->nullable();
            $table->string('difficulty');
            $table->string('equipment');
            $table->text('instructions');
            $table->text('form_tips');
            $table->string('gif_url')->nullable();
            $table->boolean('is_custom')->default(false);
            $table->unsignedBigInteger('user_id')->nullable();
            $table->timestamps();
            $table->charset = 'utf8mb4';
            $table->collation = 'utf8mb4_unicode_ci';

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercises');
    }
};
