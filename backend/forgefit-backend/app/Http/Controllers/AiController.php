<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\OpenAiService;

class AiController extends Controller
{
    private function resolveAiService()
    {
        try {
            return app()->make(OpenAiService::class);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('AI service resolution failed', ['error' => $e->getMessage()]);
            return null;
        }
    }

    public function chat(Request $request)
    {
        $v = validator($request->all(), [
            'message' => 'required|string'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $ai = $this->resolveAiService();
        if (!$ai) {
            return response()->json(['message' => 'AI service unavailable'], 503);
        }

        try {
            $reply = $ai->chat($request->input('message'), $request->user());
            return response($reply, 200)->header('Content-Type', 'text/plain; charset=UTF-8');
        } catch (\Throwable $e) {
            return response()->json(['message' => 'AI service error'], 503);
        }
    }

    public function generatePlan(Request $request)
    {
        $ai = $this->resolveAiService();
        if (!$ai) {
            return response()->json(['message' => 'AI service unavailable'], 503);
        }

        try {
            $plan = $ai->generatePlan($request->user());
            return response()->json(['data' => ['plan' => $plan]]);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('AI generatePlan Error', [
                'message' => $e->getMessage(),
                'code' => $e->getCode(),
            ]);
            $msg = $e->getMessage();
            if (strpos($msg, 'Invalid JSON') !== false) {
                $msg = 'AI returned invalid response. Try again.';
            }
            return response()->json(['message' => 'Failed to generate plan', 'error' => $msg], 503);
        }
    }

    public function overloadSuggestion(Request $request)
    {
        $v = validator($request->all(), [
            'exercise_name' => 'required|string',
            'last_weight' => 'required|numeric',
            'last_reps' => 'required|integer',
            'target_reps' => 'required|integer'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $ai = $this->resolveAiService();
        if (!$ai) {
            return response()->json(['message' => 'AI service unavailable'], 503);
        }

        try {
            $s = $ai->overloadSuggestion(
                $request->input('exercise_name'),
                (float) $request->input('last_weight'),
                (int) $request->input('last_reps'),
                (int) $request->input('target_reps'),
                $request->user()
            );
            return response()->json(['data' => ['suggestion' => $s]]);
        } catch (\Throwable $e) {
            return response()->json(['message' => 'AI service unavailable', 'error' => $e->getMessage()], 503);
        }
    }

    public function missingMuscles(Request $request)
    {
        $v = validator($request->all(), [
            'recent_muscles' => 'sometimes|array'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $ai = $this->resolveAiService();
        if (!$ai) {
            return response()->json(['message' => 'AI service unavailable'], 503);
        }

        try {
            $s = $ai->missingMuscles($request->input('recent_muscles', []), $request->user());
            return response()->json(['data' => ['suggestion' => $s]]);
        } catch (\Throwable $e) {
            return response()->json(['message' => 'AI service unavailable', 'error' => $e->getMessage()], 503);
        }
    }

    public function formAdvice(Request $request)
    {
        $v = validator($request->all(), [
            'exercise_name' => 'required|string'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $ai = $this->resolveAiService();
        if (!$ai) {
            return response()->json(['message' => 'AI service unavailable'], 503);
        }

        try {
            $a = $ai->formAdvice($request->input('exercise_name'), $request->user());
            return response()->json(['data' => ['advice' => $a]]);
        } catch (\Throwable $e) {
            return response()->json(['message' => 'AI service unavailable', 'error' => $e->getMessage()], 503);
        }
    }
}
