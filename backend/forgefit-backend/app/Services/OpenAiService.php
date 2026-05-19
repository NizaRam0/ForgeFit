<?php

namespace App\Services;

use App\Models\User;
use App\Models\Exercise;
use App\Models\WorkoutLog;
use OpenAI\Factory;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class OpenAiService
{
    protected $client;

    public function __construct()
    {
        $apiKey = config('openai.api_key');

        if (!is_string($apiKey) || trim($apiKey) === '') {
            throw new \RuntimeException('OPENAI_API_KEY is not configured.');
        }

        $this->client = (new Factory())->withApiKey($apiKey)->make();
    }

    private function chatSystemPrompt(User $user): string
    {
        return $this->buildChatPrompt($user);
    }

    private function planSystemPrompt(User $user): string
    {
        return 'You are ForgeFit AI coach. When generating a workout plan, return JSON only, use exactly the user\'s requested workout count, and only use exercises that match the user\'s exact fitness level. Never mix levels or add extra workouts.';
    }

    public function chat(string $message, User $user): string
    {
        try {
            Log::info('AI Chat Request', [
                'user_id' => $user->id,
                'message' => substr($message, 0, 100),
            ]);

            $messages = [
                ['role' => 'system', 'content' => $this->chatSystemPrompt($user)],
                ['role' => 'user', 'content' => $message],
            ];

            $resp = $this->client->chat()->create([
                'model' => 'gpt-4o-mini',
                'messages' => $messages,
                'max_tokens' => 500,
                'temperature' => 0.7,
            ]);

            $reply = $resp->choices[0]->message->content ?? '';
            
            Log::info('AI Chat Response', [
                'user_id' => $user->id,
                'response_length' => strlen($reply),
                'model' => $resp->model ?? 'unknown',
            ]);

            return $reply;
        } catch (\Throwable $e) {
            Log::error('AI Chat Error', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            throw $e;
        }
    }

    private function buildChatPrompt(User $user): string
    {
        $user->loadMissing('workoutLogs.logExercises.setEntries');

        $logs = $user->workoutLogs
            ->sortByDesc('date')
            ->values();

        $recentLogs = $logs->take(5);
        $weeklyCount = $logs->filter(function ($log) {
            return Carbon::parse($log->date)->greaterThanOrEqualTo(now()->startOfWeek());
        })->count();
        $totalVolume = $logs->sum(function ($log) {
            return $log->logExercises->sum(function ($exercise) {
                return $exercise->setEntries->sum(function ($set) {
                    return ((float) $set->weight) * ((int) $set->reps);
                });
            });
        });
        $streak = $this->currentStreak($logs);
        $trend = $this->progressiveOverloadTrend($logs);

        $recentSummary = $recentLogs->map(function ($log) {
            $exerciseSummary = $log->logExercises->map(function ($exercise) {
                $sets = $exercise->setEntries->map(function ($set) {
                    return sprintf('%s x %s', rtrim(rtrim(number_format((float) $set->weight, 2, '.', ''), '0'), '.'), $set->reps);
                })->implode(', ');

                return sprintf('%s [%s]', $exercise->exercise_name ?: 'Exercise', $sets ?: 'no sets logged');
            })->implode(' | ');

            return sprintf('%s: %s', Carbon::parse($log->date)->toDateString(), $exerciseSummary ?: 'no exercises logged');
        })->implode("\n");

        $displayName = $user->nickname ?: $user->name;
        $equipment = is_array($user->available_equipment) ? implode(', ', $user->available_equipment) : (string) $user->available_equipment;
        $gender = $user->gender ?: 'Not specified';

        return <<<PROMPT
You are a professional AI gym coach. Answer in plain conversational language only. Never output JSON, code blocks, bullet-only dumps, or raw data structures.

User Profile:
Name: {$user->name}
Nickname: {$displayName}
Age: {$user->age} | Gender: {$gender}
Weight: {$user->weight_kg}kg | Height: {$user->height_cm}cm
Goal: {$user->goal} | Fitness Level: {$user->fitness_level}
Equipment: {$equipment}
Target workouts per week: {$user->workouts_per_week}

Training Summary:
- Total volume lifted all time: {$totalVolume}kg
- Workouts this week: {$weeklyCount}
- Current streak: {$streak} days
- Progressive overload trend: {$trend}
- Last 5 sessions:
{$recentSummary}

Use this context to answer the user's question naturally and specifically.
PROMPT;
    }

    private function currentStreak($logs): int
    {
        $dates = $logs
            ->map(fn ($log) => Carbon::parse($log->date)->startOfDay()->toDateString())
            ->unique()
            ->sortDesc()
            ->values();

        if ($dates->isEmpty()) {
            return 0;
        }

        $streak = 0;
        $cursor = Carbon::today();

        foreach ($dates as $date) {
            if ($date !== $cursor->toDateString()) {
                break;
            }

            $streak++;
            $cursor = $cursor->subDay();
        }

        return $streak;
    }

    private function progressiveOverloadTrend($logs): string
    {
        if ($logs->count() < 2) {
            return 'Not enough history yet';
        }

        $latest = $logs->first();
        $previous = $logs->slice(1)->first();

        $latestVolume = $latest->logExercises->sum(function ($exercise) {
            return $exercise->setEntries->sum(function ($set) {
                return ((float) $set->weight) * ((int) $set->reps);
            });
        });

        $previousVolume = $previous->logExercises->sum(function ($exercise) {
            return $exercise->setEntries->sum(function ($set) {
                return ((float) $set->weight) * ((int) $set->reps);
            });
        });

        if ($latestVolume > $previousVolume) {
            return 'Improving';
        }

        if ($latestVolume < $previousVolume) {
            return 'Slightly down from the last session';
        }

        return 'Stable';
    }

    public function generatePlan(User $user): array
    {
        try {
            $displayName = $user->nickname ?: $user->name;
            $workoutCount = max(1, (int) $user->workouts_per_week);
            $allowedExercises = $this->allowedExercisesPrompt($user->fitness_level);
            $prompt = "Generate a workout plan JSON for user: nickname={$displayName}, age={$user->age}, weight={$user->weight_kg}, height={$user->height_cm}, goal={$user->goal}, fitness_level={$user->fitness_level}, workouts_per_week={$workoutCount}, equipment=".json_encode($user->available_equipment).".\n\nReturn exactly {$workoutCount} workout days. Use only exercises from this exact fitness level. Do not include beginner exercises when the user is intermediate. Do not include intermediate exercises when the user is beginner. Do not mix levels.\nAllowed exercises for {$user->fitness_level}:\n{$allowedExercises}";

            Log::info('AI Generate Plan Request', [
                'user_id' => $user->id,
                'user_name' => $displayName,
                'goal' => $user->goal,
                'fitness_level' => $user->fitness_level,
            ]);

            $resp = $this->client->chat()->create([
                'model' => 'gpt-3.5-turbo',
                'messages' => [['role'=>'system','content'=>$this->planSystemPrompt($user)], ['role'=>'user','content'=>$prompt]],
                'max_tokens' => 1500,
                'temperature' => 0.5,
            ]);

            $content = $resp->choices[0]->message->content ?? '';
            
            Log::info('AI Generate Plan Raw Response', [
                'user_id' => $user->id,
                'content_length' => strlen($content),
                'content_preview' => substr($content, 0, 200),
            ]);

            // Force JSON: try decode
            $json = json_decode($content, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                // try to extract JSON substring
                preg_match('/(\{.*\})/s', $content, $m);
                if (isset($m[1])) {
                    $json = json_decode($m[1], true);
                }
            }

            if (!is_array($json)) {
                Log::error('AI Generate Plan Invalid JSON', [
                    'user_id' => $user->id,
                    'content' => substr($content, 0, 500),
                ]);
                throw new \Exception('Invalid JSON from AI');
            }

            $json = $this->normalizePlan($json, $user);

            Log::info('AI Generate Plan Success', [
                'user_id' => $user->id,
                'plan_keys' => array_keys($json),
            ]);

            return $json;
        } catch (\Throwable $e) {
            Log::error('AI Generate Plan Error', [
                'user_id' => $user->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            throw $e;
        }
    }

    private function allowedExercisesPrompt(string $fitnessLevel): string
    {
        $level = match ($fitnessLevel) {
            'Beginner', 'Intermediate', 'Advanced' => $fitnessLevel,
            default => 'Beginner',
        };

        $exercises = Exercise::query()
            ->where('difficulty', $level)
            ->orderBy('difficulty')
            ->orderBy('muscle_group')
            ->orderBy('name')
            ->limit(120)
            ->get(['name', 'muscle_group', 'difficulty']);

        if ($exercises->isEmpty()) {
            return 'No exercises available.';
        }

        return $exercises->map(function (Exercise $exercise) {
            return sprintf('- %s | %s | %s', $exercise->name, $exercise->muscle_group, $exercise->difficulty);
        })->implode("\n");
    }

    private function normalizePlan(array $plan, User $user): array
    {
        $allowedNames = Exercise::query()
            ->where('difficulty', $user->fitness_level)
            ->pluck('name')
            ->map(fn ($name) => strtolower((string) $name))
            ->all();

        $targetDays = max(1, (int) $user->workouts_per_week);
        $days = array_slice($plan['days'] ?? [], 0, $targetDays);

        $cleanDays = [];
        foreach ($days as $day) {
            if (!is_array($day)) {
                continue;
            }

            $dayExercises = array_values(array_filter($day['exercises'] ?? [], function ($exercise) use ($allowedNames) {
                if (!is_array($exercise)) {
                    return false;
                }

                $name = strtolower((string) ($exercise['name'] ?? ''));
                return $name !== '' && in_array($name, $allowedNames, true);
            }));

            if (empty($dayExercises)) {
                continue;
            }

            $day['exercises'] = $dayExercises;
            $cleanDays[] = $day;
        }

        $plan['days'] = array_slice($cleanDays, 0, $targetDays);
        return $plan;
    }

    public function overloadSuggestion(string $exercise_name, float $last_weight, int $last_reps, int $target_reps, User $user): string
    {
        try {
            $prompt = "Given exercise {$exercise_name}, last weight {$last_weight}, last reps {$last_reps}, target reps {$target_reps}, suggest next loading progression.";
            return $this->chat($prompt, $user);
        } catch (\Throwable $e) {
            throw $e;
        }
    }

    public function missingMuscles(array $muscles, User $user): string
    {
        try {
            $prompt = "User recent muscles: ".implode(', ',$muscles).". Suggest missing muscles and corrections.";
            return $this->chat($prompt,$user);
        } catch (\Throwable $e) {
            throw $e;
        }
    }

    public function formAdvice(string $exercise, User $user): string
    {
        try {
            $prompt = "Provide form advice for exercise: {$exercise}.";
            return $this->chat($prompt, $user);
        } catch (\Throwable $e) {
            throw $e;
        }
    }
}
