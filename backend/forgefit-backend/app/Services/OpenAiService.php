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
        return 'You are ForgeFit AI coach. When generating a workout plan, return ONLY valid JSON with this exact structure: {"planName": "...", "days": [{"dayName": "...", "muscleGroups": [...], "exercises": [{"name": "...", "sets": N, "reps": N}]}]}.

UPPER BODY / PUSH / PULL days must include AT LEAST 8 exercises per day with exactly this breakdown:
- 3 chest OR back exercises (compound + isolation)
- 2 tricep OR bicep exercises
- 2 shoulder OR forearm exercises
- 1 traps exercise (e.g. Barbell Shrug)

LEG days must hit HIGH INTENSITY with 6-7 exercises:
- 2 heavy compound movements at 4-6 sets, 5-8 reps (e.g. Barbell Squat, Deadlift, Romanian Deadlift)
- 2 accessory compound movements (e.g. Leg Press, Bulgarian Split Squat)
- 2-3 isolation movements (Leg Curl, Leg Extension, Calf Raise)

Use exactly the user requested workout count. Only use exercises matching the user exact fitness level. Never mix levels.';
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

        $dateSet = array_flip($dates->all());
$streak = 0;
$cursor = Carbon::today();

if (!isset($dateSet[$cursor->toDateString()])) {
    $cursor = $cursor->subDay();
}

while (isset($dateSet[$cursor->toDateString()])) {
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
            $prompt = "Generate a workout plan JSON for: nickname={$displayName}, age={$user->age}, weight={$user->weight_kg}kg, height={$user->height_cm}cm, goal={$user->goal}, fitness_level={$user->fitness_level}, workouts_per_week={$workoutCount}, equipment=".json_encode($user->available_equipment).".\n\nReturn exactly {$workoutCount} workout days. Structure each upper/push/pull day with: 3 chest/back exercises + 2 tricep/bicep exercises + 2 shoulder/forearm exercises + 1 traps exercise = 8+ exercises. Structure each leg day with 2 heavy compounds (4-5 sets, 5-8 reps) + accessories = 6-7 exercises total for maximum intensity.\n\nOnly use exercises from this exact fitness level list. Do not mix levels.\nAllowed exercises for {$user->fitness_level}:\n{$allowedExercises}";

            Log::info('AI Generate Plan Request', [
                'user_id' => $user->id,
                'user_name' => $displayName,
                'goal' => $user->goal,
                'fitness_level' => $user->fitness_level,
            ]);

            $resp = $this->client->chat()->create([
                'model' => 'gpt-3.5-turbo',
                'messages' => [['role'=>'system','content'=>$this->planSystemPrompt($user)], ['role'=>'user','content'=>$prompt]],
                'max_tokens' => 3500,
                'temperature' => 0.5,
            ]);

            $content = $resp->choices[0]->message->content ?? '';

            Log::info('AI Generate Plan Raw Response', [
                'user_id' => $user->id,
                'content_length' => strlen($content),
                'content_preview' => substr($content, 0, 200),
            ]);

            // Force JSON: try decode. If the model returns surrounding text, try to extract a balanced JSON block.
            $json = json_decode($content, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                $maybe = $this->extractBalancedJson($content);
                if ($maybe !== null) {
                    $json = json_decode($maybe, true);
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
            ->map(fn ($name) => $this->normalizeExerciseName((string) $name))
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

                $name = $this->normalizeExerciseName((string) ($exercise['name'] ?? ''));
                if ($name === '') {
                    return false;
                }

                // Exact match after normalization
                if (in_array($name, $allowedNames, true)) {
                    return true;
                }

                // Fuzzy: allow if Levenshtein distance <= 3 (handles plurals, typos, minor variations)
                foreach ($allowedNames as $allowed) {
                    if (levenshtein($name, $allowed) <= 3) {
                        return true;
                    }
                }

                // Substring: allow if the AI name contains a known name or vice versa
                foreach ($allowedNames as $allowed) {
                    if (str_contains($name, $allowed) || str_contains($allowed, $name)) {
                        return true;
                    }
                }

                return false;
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

    private function normalizeExerciseName(string $name): string
    {
        $name = strtolower($name);
        $name = preg_replace('/[^a-z0-9 ]/', '', $name); // strip punctuation
        $name = preg_replace('/\s+/', ' ', trim($name));
        return $name;
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

    private function extractBalancedJson(string $text): ?string
    {
        $len = strlen($text);
        $start = null;
        $open = null;
        for ($i = 0; $i < $len; $i++) {
            $ch = $text[$i];
            if ($ch === '{' || $ch === '[') {
                $start = $i;
                $open = $ch;
                break;
            }
        }

        if ($start === null) {
            return null;
        }

        $pairs = ['{' => '}', '[' => ']'];
        $stack = [];
        for ($i = $start; $i < $len; $i++) {
            $ch = $text[$i];
            if ($ch === '{' || $ch === '[') {
                array_push($stack, $ch);
            } elseif ($ch === '}' || $ch === ']') {
                if (empty($stack)) {
                    return null;
                }
                $last = array_pop($stack);
                if ($pairs[$last] !== $ch) {
                    // mismatched brackets
                    return null;
                }
                if (empty($stack)) {
                    return substr($text, $start, $i - $start + 1);
                }
            }
        }

        return null;
    }
}
