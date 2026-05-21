<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'nickname' => 'required|string|max:50|unique:users,nickname',
            'name' => 'sometimes|nullable|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'gender' => 'sometimes|nullable|string|max:30',
            'age' => 'sometimes|nullable|integer|min:10|max:100',
            'weight_kg' => 'sometimes|nullable|numeric|min:20|max:300',
            'height_cm' => 'sometimes|nullable|numeric|min:100|max:250',
            'goal' => 'sometimes|nullable|string|max:100',
            'fitness_level' => 'sometimes|nullable|string|max:100',
            'available_equipment' => 'sometimes|nullable|array',
            'workouts_per_week' => 'sometimes|nullable|integer|min:1|max:7',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $validated = $validator->validated();

        $user = User::create([
            'name' => $validated['name'] ?? $validated['nickname'],
            'nickname' => $validated['nickname'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'gender' => $validated['gender'] ?? null,
            'age' => $validated['age'] ?? null,
            'weight_kg' => $validated['weight_kg'] ?? null,
            'height_cm' => $validated['height_cm'] ?? null,
            'goal' => $validated['goal'] ?? null,
            'fitness_level' => $validated['fitness_level'] ?? null,
            'available_equipment' => $validated['available_equipment'] ?? null,
            'workouts_per_week' => $validated['workouts_per_week'] ?? null,
            'profile_complete' => false,
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'data' => [
                'user' => new UserResource($user),
                'token' => $token,
            ],
            'message' => 'Registration successful',
        ], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'identifier' => 'required|string',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $identifier = trim($request->string('identifier')->toString());
        $password = $request->string('password')->toString();

        $credentials = filter_var($identifier, FILTER_VALIDATE_EMAIL)
            ? ['email' => $identifier, 'password' => $password]
            : ['nickname' => $identifier, 'password' => $password];

        if (!Auth::guard('web')->validate($credentials)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = filter_var($identifier, FILTER_VALIDATE_EMAIL)
            ? User::where('email', $identifier)->first()
            : User::where('nickname', $identifier)->first();

        if (!$user) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'data' => [
                'user' => new UserResource($user),
                'token' => $token,
            ],
            'message' => 'Login successful',
        ]);
    }

    public function logout(Request $request)
    {
        $token = $request->user()->currentAccessToken();

        if ($token) {
            $token->delete();
        }

        return response()->json(['message' => 'Logged out']);
    }

    public function me(Request $request)
    {
        return response()->json(['data' => ['user' => new UserResource($request->user())]]);
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        $table = $user->getTable();

        $validator = Validator::make($request->all(), [
            'nickname' => ['sometimes', 'nullable', 'string', 'max:50', Rule::unique('users', 'nickname')->ignore($user->id)],
            'name' => 'sometimes|nullable|string|max:100',
            'email' => ['sometimes', 'nullable', 'email', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'sometimes|nullable|string|min:8',
            'gender' => 'sometimes|nullable|string|max:30',
            'age' => 'sometimes|nullable|integer|min:10|max:100',
            'weight_kg' => 'sometimes|nullable|numeric|min:20|max:300',
            'height_cm' => 'sometimes|nullable|numeric|min:100|max:250',
            'goal' => 'sometimes|nullable|string|max:100',
            'fitness_level' => 'sometimes|nullable|string|max:100',
            'available_equipment' => 'sometimes|nullable|array',
            'workouts_per_week' => 'sometimes|nullable|integer|min:1|max:7',
            'profile_complete' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $validator->errors()], 422);
        }

        $validated = $validator->validated();
        $updates = [];

        foreach (array_keys($validated) as $field) {
            if (Schema::hasColumn($table, $field)) {
                $updates[$field] = $validated[$field];
            }
        }

        if (array_key_exists('password', $updates) && $updates['password'] !== null) {
            $updates['password'] = Hash::make($updates['password']);
        } else {
            unset($updates['password']);
        }

        if (Schema::hasColumn($table, 'profile_complete')) {
            $updates['profile_complete'] = $request->has('profile_complete')
                ? $request->boolean('profile_complete')
                : true;
        }

        $user->update($updates);
        $user->refresh();

        return response()->json([
            'data' => ['user' => new UserResource($user)],
            'message' => 'Profile updated',
        ]);
    }
}
