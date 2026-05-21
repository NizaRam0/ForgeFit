<?php

namespace App\Http\Controllers;

use App\Models\Exercise;
use App\Http\Resources\ExerciseResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ExerciseController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated'], 401);
        }
        $q = Exercise::query();

        // Return built-in (user_id is null) OR user's custom
        $q->where(function($qr) use ($user){
            $qr->whereNull('user_id')->orWhere('user_id', $user->id);
        });

        if ($request->has('muscle_group')) {
            $q->where('muscle_group', $request->muscle_group);
        }

        if ($request->has('search')) {
            $q->where('name', 'like', '%'.$request->search.'%');
        }

        $exercises = $q->orderBy('muscle_group','asc')->orderBy('name','asc')->get();

        return response()->json(['data' => ExerciseResource::collection($exercises)]);
    }

    public function store(Request $request)
    {
        $v = Validator::make($request->all(), [
            'name' => 'required|string',
            'muscle_group' => 'required|string',
            'difficulty' => 'required|in:Beginner,Intermediate,Advanced',
            'equipment' => 'required|string',
            'instructions' => 'required|string',
            'form_tips' => 'required|string'
        ]);

        if ($v->fails()) {
            return response()->json(['message'=>'Validation failed','errors'=>$v->errors()],422);
        }

        $exercise = Exercise::create(array_merge($request->only(['name','muscle_group','secondary_muscles','difficulty','equipment','instructions','form_tips','gif_url']), [
            'id' => (string) Str::uuid(),
            'is_custom' => true,
            'user_id' => $request->user()->id,
        ]));

        return response()->json(['data'=>['exercise'=>new ExerciseResource($exercise)], 'message'=>'Exercise created'], 201);
    }

    public function destroy(Request $request, $id)
    {
        $exercise = Exercise::findOrFail($id);
        if ($exercise->user_id !== $request->user()->id) {
            return response()->json(['message'=>'Forbidden'],403);
        }

        $exercise->delete();
        return response()->json(['message'=>'Exercise deleted']);
    }
}
