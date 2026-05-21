<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

/**
 * @extends Factory<User>
 */
class UserFactory extends Factory
{
    /**
     * The current password being used by the factory.
     */
    protected static ?string $password;

    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'name' => fake()->name(),
            'nickname' => fake()->unique()->userName(),
            'email' => fake()->unique()->safeEmail(),
            'password' => static::$password ??= Hash::make('password'),
            'gender' => fake()->randomElement(['male', 'female', 'non-binary', null]),
            'age' => fake()->numberBetween(18, 70),
            'weight_kg' => fake()->randomFloat(2, 45, 140),
            'height_cm' => fake()->randomFloat(2, 145, 210),
            'goal' => fake()->randomElement(['Build Muscle', 'Lose Weight', 'Increase Strength', 'Improve Endurance', 'General Fitness', null]),
            'fitness_level' => fake()->randomElement(['Beginner', 'Intermediate', 'Advanced', null]),
            'available_equipment' => ['dumbbells', 'bench'],
            'workouts_per_week' => fake()->numberBetween(1, 7),
            'profile_complete' => false,
            'remember_token' => Str::random(10),
        ];
    }

    /**
     * Indicate that the model's email address should be unverified.
     */
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'profile_complete' => false,
        ]);
    }
}
