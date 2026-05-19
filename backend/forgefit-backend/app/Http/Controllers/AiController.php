<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\OpenAiService;

class AiController extends Controller
{
    protected OpenAiService $ai;

    public function __construct(OpenAiService $ai)
    {
        $this->ai = $ai;
    }

    public function chat(Request $request)
    {
        try {
            $reply = $this->ai->chat($request->message, $request->user());
            return response($reply, 200)->header('Content-Type', 'text/plain; charset=UTF-8');
        } catch (\Throwable $e) {
            return response('AI service unavailable', 503)->header('Content-Type', 'text/plain; charset=UTF-8');
        }
    }

    public function generatePlan(Request $request)
    {
        try {
            $plan = $this->ai->generatePlan($request->user());
            return response()->json(['data'=>['plan'=>$plan]]);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('AI generatePlan Error', [
                'message' => $e->getMessage(),
                'code' => $e->getCode(),
            ]);
            $msg = $e->getMessage();
            if (strpos($msg, 'Invalid JSON') !== false) {
                $msg = 'AI returned invalid response. Try again.';
            }
            return response()->json(['message'=>'Failed to generate plan','error'=>$msg],503);
        }
    }

    public function overloadSuggestion(Request $request)
    {
        try {
            $s = $this->ai->overloadSuggestion($request->exercise_name, (float)$request->last_weight, (int)$request->last_reps, (int)$request->target_reps, $request->user());
            return response()->json(['data'=>['suggestion'=>$s]]);
        } catch (\Throwable $e) {
            return response()->json(['message'=>'AI service unavailable','error'=>$e->getMessage()],503);
        }
    }

    public function missingMuscles(Request $request)
    {
        try {
            $s = $this->ai->missingMuscles($request->recent_muscles ?? [], $request->user());
            return response()->json(['data'=>['suggestion'=>$s]]);
        } catch (\Throwable $e) {
            return response()->json(['message'=>'AI service unavailable','error'=>$e->getMessage()],503);
        }
    }

    public function formAdvice(Request $request)
    {
        try {
            $a = $this->ai->formAdvice($request->exercise_name, $request->user());
            return response()->json(['data'=>['advice'=>$a]]);
        } catch (\Throwable $e) {
            return response()->json(['message'=>'AI service unavailable','error'=>$e->getMessage()],503);
        }
    }
}
