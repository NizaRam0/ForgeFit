<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_issues_mobile_token_and_returns_user(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'nickname' => 'coachjane',
            'name' => 'Jane Coach',
            'email' => 'jane@example.com',
            'password' => 'password123',
            'goal' => 'Build Muscle',
            'fitness_level' => 'Beginner',
            'available_equipment' => ['dumbbells'],
            'workouts_per_week' => 4,
        ]);

        $response->assertCreated()
            ->assertJsonPath('message', 'Registration successful')
            ->assertJsonStructure([
                'data' => [
                    'user' => [
                        'id', 'name', 'nickname', 'email', 'gender', 'age', 'weight_kg', 'height_cm', 'goal',
                        'fitness_level', 'available_equipment', 'workouts_per_week', 'profile_complete', 'created_at', 'updated_at',
                    ],
                    'token',
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'nickname' => 'coachjane',
            'email' => 'jane@example.com',
            'profile_complete' => 0,
        ]);

        if ((string) ($response->json('data.token') ?? '') === '') {
            throw new \RuntimeException('Expected a registration token to be returned.');
        }
    }

    public function test_login_accepts_nickname_and_issues_token(): void
    {
        $user = User::factory()->create([
            'nickname' => 'nickfit',
            'email' => 'nick@example.com',
            'password' => Hash::make('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'identifier' => 'nickfit',
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonPath('message', 'Login successful')
            ->assertJsonPath('data.user.id', $user->id)
            ->assertJsonStructure([
                'data' => [
                    'user' => ['id', 'nickname', 'email'],
                    'token',
                ],
            ]);

        if ((string) ($response->json('data.token') ?? '') === '') {
            throw new \RuntimeException('Expected a login token to be returned.');
        }
    }

    public function test_login_rejects_invalid_credentials(): void
    {
        User::factory()->create([
            'nickname' => 'wronguser',
            'email' => 'wrong@example.com',
            'password' => Hash::make('password123'),
        ]);

        $this->postJson('/api/auth/login', [
            'identifier' => 'wronguser',
            'password' => 'bad-password',
        ])->assertStatus(401)
          ->assertJsonPath('message', 'Invalid credentials');
    }

    public function test_authenticated_profile_flow_uses_bearer_token(): void
    {
        $user = User::factory()->create([
            'nickname' => 'fitmate',
            'email' => 'fitmate@example.com',
            'password' => Hash::make('password123'),
            'profile_complete' => false,
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        $meResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/auth/me');

        $meResponse->assertOk()
            ->assertJsonPath('data.user.nickname', 'fitmate');

        $profileResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->putJson('/api/auth/profile', [
                'nickname' => 'fitmate',
                'age' => 29,
                'gender' => 'Male',
                'weight_kg' => 82.5,
                'height_cm' => 181,
                'goal' => 'Increase Strength',
                'fitness_level' => 'Intermediate',
                'available_equipment' => ['Dumbbells', 'Pull-Up Bar'],
                'workouts_per_week' => 4,
                'profile_complete' => true,
            ]);

        $profileResponse->assertOk()
            ->assertJsonPath('message', 'Profile updated')
            ->assertJsonPath('data.user.nickname', 'fitmate')
            ->assertJsonPath('data.user.gender', 'Male')
            ->assertJsonPath('data.user.workouts_per_week', 4)
            ->assertJsonPath('data.user.profile_complete', true);

        $logoutResponse = $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/auth/logout');

        $logoutResponse->assertOk()
            ->assertJsonPath('message', 'Logged out');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/auth/me')
            ->assertUnauthorized();
    }
}