<?php

namespace App\Http\Controllers;

use App\Models\WorkoutTemplate;
use App\Models\WorkoutTemplateExercise;
use App\Http\Resources\WorkoutTemplateResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;

class TemplateController extends Controller
{
    public function index(Request $request)
    {
        $templates = WorkoutTemplate::where('user_id', $request->user()->id)
            ->with('templateExercises.exercise')
            ->orderBy('created_at','desc')
            ->get();

        return response()->json(['data' => WorkoutTemplateResource::collection($templates)]);
    }

    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string',
            'description' => 'sometimes|string|nullable',
            'muscle_groups' => 'required|array|min:1',
            'exercises' => 'required|array|min:1'
        ]);

        if ($v->fails()) {
            return response()->json(['message'=>'Validation failed','errors'=>$v->errors()],422);
        }

        $templateId = (string) Str::uuid();

        DB::transaction(function() use ($request, $templateId) {
            $template = WorkoutTemplate::create([
                'id' => $templateId,
                'user_id' => $request->user()->id,
                'name' => $request->name,
                'description' => $request->description,
                'muscle_groups' => $request->muscle_groups,
                'is_ai_generated' => false,
            ]);

            foreach ($request->exercises as $ex) {
                WorkoutTemplateExercise::create([
                    'template_id' => $templateId,
                    'exercise_id' => $ex['exercise_id'],
                    'sets' => $ex['sets'],
                    'target_reps' => $ex['target_reps'],
                    'sort_order' => $ex['sort_order'] ?? 0,
                ]);
            }
        });

        $template = WorkoutTemplate::with('templateExercises.exercise')->find($templateId);
        return response()->json(['data'=>['template'=>new WorkoutTemplateResource($template)], 'message'=>'Template created'], 201);
    }

    public function destroy(Request $request, $id)
    {
        $template = WorkoutTemplate::findOrFail($id);
        if ($template->user_id !== $request->user()->id) {
            return response()->json(['message'=>'Forbidden'],403);
        }

        $template->delete();
        return response()->json(['message'=>'Template deleted']);
    }
}
