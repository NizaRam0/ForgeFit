<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Http\Resources\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Carbon\Carbon;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $v = Validator::make($request->all(), [
            'nickname' => 'required|string|max:50|unique:users,nickname',
            'name' => 'sometimes|nullable|string|max:100',
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
            'gender' => 'sometimes|nullable|string|max:30',
            'age' => 'sometimes|nullable|integer|min:10|max:100',
            'weight_kg' => 'sometimes|nullable|numeric|min:20|max:300',
            'height_cm' => 'sometimes|nullable|numeric|min:100|max:250',
            'goal' => 'sometimes|nullable|in:Build Muscle,Lose Weight,Increase Strength,Improve Endurance,General Fitness',
            'fitness_level' => 'sometimes|nullable|in:Beginner,Intermediate,Advanced',
            'available_equipment' => 'sometimes|nullable|array|min:1',
            'workouts_per_week' => 'sometimes|nullable|integer|min:1|max:6'
        ]);

        if ($v->fails()) {
            return response()->json(['message' => 'Validation failed', 'errors' => $v->errors()], 422);
        }

        $base = [
            'name' => $request->name ?? $request->nickname,
            'nickname' => $request->nickname,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'profile_complete' => false,
        ];

        $optional = array_filter($request->only([
            'gender','age','weight_kg','height_cm','goal','fitness_level','available_equipment','workouts_per_week'
        ]), function($v) { return !is_null($v); });

        $user = User::create(array_merge($base, $optional));

        // create a mobile token that expires in 30 days
        $expires = Carbon::now()->addDays(30);
        $token = $user->createToken('mobile', ['*'], $expires)->plainTextToken;

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

        $user = filter_var($identifier, FILTER_VALIDATE_EMAIL)
            ? User::where('email', $identifier)->first()
            : User::where('nickname', $identifier)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
        if (method_exists($user, 'tokens')) {
            $maxTokens = 5;
            $expiryDays = 30;
            $cutoff = Carbon::now()->subDays($expiryDays);

            // remove tokens older than expiry window
            $user->tokens()->where('name', 'mobile')->where('created_at', '<', $cutoff)->delete();

            // if too many tokens remain, delete oldest to make room
            $tokens = $user->tokens()->where('name', 'mobile')->orderBy('created_at', 'asc')->get();
            if ($tokens->count() >= $maxTokens) {
                $deleteCount = $tokens->count() - ($maxTokens - 1);
                $idsToDelete = $tokens->take($deleteCount)->pluck('id')->all();
                if (!empty($idsToDelete)) {
                    $user->tokens()->whereIn('id', $idsToDelete)->delete();
                }
            }
        }

        $expires = Carbon::now()->addDays(30);
        $token = $user->createToken('mobile', ['*'], $expires)->plainTextToken;

        return response()->json(['data' => ['user' => new UserResource($user), 'token' => $token], 'message' => 'Login successful']);
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

        // Only update profile_complete if it's explicitly provided by the client.
        $user->update($data);

        return response()->json(['data'=>['user'=>new UserResource($user)], 'message'=>'Profile updated']);
    }
}
