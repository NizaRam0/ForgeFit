<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ExerciseController;
use App\Http\Controllers\TemplateController;
use App\Http\Controllers\LogController;
use App\Http\Controllers\AiController;

Route::prefix('auth')->group(function(){
    Route::post('register', [AuthController::class,'register']);
    Route::post('login', [AuthController::class,'login']);

    Route::middleware('auth:sanctum')->group(function(){
        Route::post('logout', [AuthController::class,'logout']);
        Route::get('me', [AuthController::class,'me']);
        Route::put('profile', [AuthController::class,'updateProfile']);
    });
});

Route::middleware('auth:sanctum')->group(function(){
    // Exercises
    Route::get('exercises', [ExerciseController::class,'index']);
    Route::post('exercises', [ExerciseController::class,'store']);
    Route::delete('exercises/{id}', [ExerciseController::class,'destroy']);

    // Templates
    Route::get('templates', [TemplateController::class,'index']);
    Route::post('templates', [TemplateController::class,'store']);
    Route::delete('templates/{id}', [TemplateController::class,'destroy']);

    // Logs
    Route::get('logs', [LogController::class,'index']);
    Route::post('logs', [LogController::class,'store']);
    Route::delete('logs/{id}', [LogController::class,'destroy']);
    Route::get('logs/stats', [LogController::class,'stats']);
    Route::get('logs/exercise/{exerciseId}/progress', [LogController::class,'exerciseProgress']);

    // AI
    Route::post('ai/chat', [AiController::class,'chat']);
    Route::post('ai/generate-plan', [AiController::class,'generatePlan']);
    Route::post('ai/overload-suggestion', [AiController::class,'overloadSuggestion']);
    Route::post('ai/missing-muscles', [AiController::class,'missingMuscles']);
    Route::post('ai/form-advice', [AiController::class,'formAdvice']);
});
