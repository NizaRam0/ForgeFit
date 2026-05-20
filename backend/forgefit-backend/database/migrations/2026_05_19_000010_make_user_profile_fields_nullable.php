<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            // Requires doctrine/dbal to alter columns on some DB drivers
            $table->integer('age')->nullable()->change();
            $table->decimal('weight_kg', 8, 2)->nullable()->change();
            $table->decimal('height_cm', 8, 2)->nullable()->change();
            $table->string('goal')->nullable()->change();
            $table->string('fitness_level')->nullable()->change();
            $table->json('available_equipment')->nullable()->change();
            $table->integer('workouts_per_week')->nullable()->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->integer('age')->nullable(false)->change();
            $table->decimal('weight_kg', 8, 2)->nullable(false)->change();
            $table->decimal('height_cm', 8, 2)->nullable(false)->change();
            $table->string('goal')->nullable(false)->change();
            $table->string('fitness_level')->nullable(false)->change();
            $table->json('available_equipment')->nullable(false)->change();
            $table->integer('workouts_per_week')->nullable(false)->change();
        });
    }
};
