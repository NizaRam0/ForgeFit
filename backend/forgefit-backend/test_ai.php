<?php

require 'vendor/autoload.php';

$dotenv = \Dotenv\Dotenv::createImmutable(__DIR__);
$dotenv->load();

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

$payload = json_encode([
    'name' => 'Test AI Coach',
    'email' => 'aitest' . time() . '@forgefit.local',
    'password' => 'testpass123',
    'nickname' => 'AITestUser',
    'age' => 28,
    'weight_kg' => 75,
    'height_cm' => 175,
    'goal' => 'Build Muscle',
    'fitness_level' => 'Intermediate',
    'available_equipment' => ['dumbbells', 'barbell', 'kettlebell'],
    'workouts_per_week' => 4,
]);

$request = Illuminate\Http\Request::create(
    '/api/auth/register',
    'POST',
    [],
    [],
    [],
    ['CONTENT_TYPE' => 'application/json'],
    $payload
);

$response = $kernel->handle($request);

$data = json_decode($response->getContent(), true);
echo "Register Response:\n";
print_r($data);

if (isset($data['data']['token'])) {
    $token = $data['data']['token'];
    $userId = $data['data']['user']['id'];
    
    echo "\n\nGenerated Token: " . substr($token, 0, 20) . "...\n";
    echo "User ID: $userId\n";
    
    // Test AI chat endpoint
    echo "\n\nTesting AI Chat Endpoint...\n";
    $chatRequest = Illuminate\Http\Request::create(
        '/api/ai/chat',
        'POST',
        [],
        [],
        [],
        [
            'HTTP_AUTHORIZATION' => "Bearer $token",
            'CONTENT_TYPE' => 'application/json',
        ],
        json_encode(['message' => 'What exercises should I do for chest?'])
    );
    
    $chatResponse = $kernel->handle($chatRequest);
    $chatData = json_decode($chatResponse->getContent(), true);
    echo "Chat Response:\n";
    print_r($chatData);
    
    // Test generate plan
    echo "\n\nTesting AI Generate Plan Endpoint...\n";
    $planRequest = Illuminate\Http\Request::create(
        '/api/ai/generate-plan',
        'POST',
        [],
        [],
        [],
        [
            'HTTP_AUTHORIZATION' => "Bearer $token",
            'CONTENT_TYPE' => 'application/json',
        ],
        json_encode([])
    );
    
    $planResponse = $kernel->handle($planRequest);
    $planData = json_decode($planResponse->getContent(), true);
    echo "Generate Plan Response:\n";
    print_r($planData);
}
?>
