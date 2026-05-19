<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $v = Validator::make($request->all(), [
            'nickname' => 'required|string|max:50',
            'name' => 'sometimes|nullable|string|max:100',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
            'gender' => 'sometimes|nullable|string|max:30',
            'age' => 'required|integer|min:10|max:100',
            'weight_kg' => 'required|numeric|min:20|max:300',
            'height_cm' => 'required|numeric|min:100|max:250',
            'goal' => 'required|in:Build Muscle,Lose Weight,Increase Strength,Improve Endurance,General Fitness',
            'fitness_level' => 'required|in:Beginner,Intermediate,Advanced',
            'available_equipment' => 'required|array|min:1',
            'workouts_per_week' => 'required|integer|min:1|max:6'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $user = User::create([
            'name' => $request->name ?? $request->nickname,
            'nickname' => $request->nickname,
            'email' => $request->email,
            'gender' => $request->gender,
            'password' => Hash::make($request->password),
            'age' => $request->age,
            'weight_kg' => $request->weight_kg,
            'height_cm' => $request->height_cm,
            'goal' => $request->goal,
            'fitness_level' => $request->fitness_level,
            'available_equipment' => $request->available_equipment,
            'workouts_per_week' => $request->workouts_per_week,
            'profile_complete' => false,
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json(['data' => ['user' => new UserResource($user), 'token' => $token], 'message' => 'Registration successful'], 201);
    }

    public function login(Request $request)
    {
        $v = Validator::make($request->all(), [
            'identifier' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $identifier = $request->string('identifier')->toString();
        $password = $request->string('password')->toString();

        $credentials = filter_var($identifier, FILTER_VALIDATE_EMAIL)
            ? ['email' => $identifier, 'password' => $password]
            : ['nickname' => $identifier, 'password' => $password];

        if (!auth()->attempt($credentials)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = auth()->user();
        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json(['data' => ['user' => new UserResource($user),'token'=>$token], 'message' => 'Login successful']);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out']);
    }

    public function me(Request $request)
    {
        return response()->json(['data' => ['user' => new UserResource($request->user())]]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $rules = [
            'nickname' => 'sometimes|string|max:50',
            'name' => 'sometimes|string|max:100',
            'email' => 'sometimes|email|unique:users,email,'.$user->id,
            'password' => 'sometimes|min:8',
            'gender' => 'sometimes|nullable|string|max:30',
            'age' => 'sometimes|integer|min:10|max:100',
            'weight_kg' => 'sometimes|numeric|min:20|max:300',
            'height_cm' => 'sometimes|numeric|min:100|max:250',
            'goal' => 'sometimes|in:Build Muscle,Lose Weight,Increase Strength,Improve Endurance,General Fitness',
            'fitness_level' => 'sometimes|in:Beginner,Intermediate,Advanced',
            'available_equipment' => 'sometimes|array|min:1',
            'workouts_per_week' => 'sometimes|integer|min:1|max:6',
            'profile_complete' => 'sometimes|boolean'
        ];

        $v = Validator::make($request->all(), $rules);
        if ($v->fails()) {
            return response()->json(['message'=>'Validation failed','errors'=>$v->errors()],422);
        }

        $data = $request->only(array_keys($rules));
        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        if (!array_key_exists('profile_complete', $data)) {
            $data['profile_complete'] = true;
        }

        $user->update($data);

        return response()->json(['data'=>['user'=>new UserResource($user)], 'message'=>'Profile updated']);
    }
}
