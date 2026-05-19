<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'profile_complete')) {
            Schema::table('users', function (Blueprint $table) {
                $table->boolean('profile_complete')->default(false)->after('workouts_per_week');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'profile_complete')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('profile_complete');
            });
        }
    }
};