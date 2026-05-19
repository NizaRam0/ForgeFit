# ForgeFit — Mobile + API

This repository contains ForgeFit: a Flutter mobile app (client) and a Laravel API backend (server). The app provides AI-assisted workout generation, workout templates, workout logging, and analytics.

This README documents the backend (`backend/forgefit-backend`), the Flutter frontend (`lib/`), and the Flutter package configuration (`pubspec.yaml`), and includes setup and run instructions.

---

## Table of Contents

- Backend (Laravel API)
  - Overview
  - Key folders & files
  - API endpoints
  - Database & migrations
  - Auth
  - AI integration
  - Running locally
- Frontend (Flutter app)
  - Overview
  - Key folders & files
  - State management
  - Networking and API client
  - AI flow (client-side)
  - Running locally
- `pubspec.yaml` summary
- Useful commands

---

## Backend (backend/forgefit-backend)

Overview

- Laravel-based REST API that stores users, exercise catalog, workout templates, and workout logs.
- Implements AI features by proxying requests to an OpenAI-backed service on the server.

Key folders & files

- `app/Http/Controllers/` — controllers for API endpoints (AuthController, ExerciseController, TemplateController, LogController, AiController).
- `app/Models/` — Eloquent models: `User`, `Exercise`, `WorkoutTemplate`, `WorkoutTemplateExercise`, `WorkoutLog`, `WorkoutLogExercise`, `SetEntry`.
- `app/Services/` — service classes (OpenAiService) that interact with external services (OpenAI).
- `routes/api.php` — registers API routes (auth, exercises, templates, logs, ai).
- `database/migrations/` — migrations that define DB schema for users, exercises, templates, logs, set entries.
- `API_ENDPOINTS.md` — human-readable summary of endpoints.

API endpoints (important ones)

- Auth
  - `POST /api/auth/register` — register a new user
  - `POST /api/auth/login` — obtain token
  - `GET /api/auth/me` — get profile (authenticated)
  - `POST /api/auth/logout` — logout (authenticated)
  - `PUT /api/auth/profile` — update profile (authenticated)
- Exercises (authenticated)
  - `GET /api/exercises` — list exercises
  - `POST /api/exercises` — create custom exercise
  - `DELETE /api/exercises/{id}` — delete exercise
- Templates (workout plans) (authenticated)
  - `GET /api/templates` — list workout templates
  - `POST /api/templates` — create template (payload includes exercises)
  - `DELETE /api/templates/{id}` — delete template
- Logs (workout sessions) (authenticated)
  - `GET /api/logs` — list workout logs
  - `POST /api/logs` — create log
  - `DELETE /api/logs/{id}` — delete log
  - `GET /api/logs/stats` — aggregate stats
  - `GET /api/logs/exercise/{exerciseId}/progress` — exercise progress
- AI (authenticated)
  - `POST /api/ai/chat` — chat endpoint
  - `POST /api/ai/generate-plan` — generate workout plan (server calls OpenAI)
  - `POST /api/ai/overload-suggestion` — progressive overload suggestion
  - `POST /api/ai/missing-muscles` — suggest missing muscles
  - `POST /api/ai/form-advice` — form advice for an exercise

Database & schema highlights

- Uses UUIDs (char(36)) for primary keys on exercises, templates, logs.
- Tables include JSON columns for `muscle_groups` and `available_equipment`.
- Migrations enforce FK relations and cascade deletes for user-owned resources.
- Relevant migrations: `create_exercises_table`, `create_workout_templates_table`, `create_workout_template_exercises_table`, `create_workout_logs_table`, `create_workout_log_exercises_table`, `create_set_entries_table`.

Authentication

- API uses Laravel Sanctum for token-based authentication. Endpoints that change data are protected with `auth:sanctum` middleware.
- Client stores token in SharedPreferences and includes `Authorization: Bearer <token>` on requests.

AI integration

- Server-side `OpenAiService` handles OpenAI API calls and returns structured plans.
- `AiController` wraps AI calls and returns standardized JSON responses.
- Server logs AI errors and falls back to returning non-200 status codes.

Running backend locally (quick)

1. Copy `.env.example` to `.env` and set DB credentials and `OPENAI_API_KEY`.
2. Install dependencies: `composer install`.
3. Generate app key: `php artisan key:generate`.
4. Run migrations: `php artisan migrate`.
5. Start dev server: `php artisan serve --port=8000`.
6. API base: `http://127.0.0.1:8000/api`.

Notes: the frontend expects the API to be reachable at `10.0.2.2:8000` for Android emulator and `localhost:8000` for iOS/macOS.

---

## Frontend (Flutter app, `lib/`)

Overview

- Flutter app implementing UI, state management, and API integration to interact with the Laravel backend.
- Features: auth, onboarding, exercise library, create/edit workouts, AI-assisted plan generation, active workout session logging, progress analytics.

Key folders & files

- `lib/main.dart` — app bootstrap, provider initialization, `AppEntry` routing.
- `lib/providers/` — ChangeNotifier providers:
  - `UserProvider` — manages user profile and onboarding flags, persists `profile_complete` in SharedPreferences.
  - `ExerciseProvider` — holds exercise catalog, search/filter, create/delete custom exercises.
  - `WorkoutProvider` — manages workout templates and logs, active workout session and analytics helpers.
  - `TimerProvider` — workout timer utilities.
- `lib/services/` — network services and API wrappers:
  - `api_service.dart` — low-level HTTP wrapper: baseUrl per platform, token storage, headers, timeout handling.
  - `auth_service.dart`, `exercise_api_service.dart`, `workout_api_service.dart`, `ai_api_service.dart` — resource-specific APIs.
- `lib/models/` — Dart model classes mirroring backend entities: `UserProfile`, `Exercise`, `WorkoutTemplate`, `WorkoutLog`, `WorkoutExercise`, `SetEntry`.
- `lib/screens/` — UI screens: `home_screen.dart` (tab shell), `workout_plans_screen.dart` (workout templates and AI generation), `build_workout_screen.dart`, `active_workout_screen.dart`, `progress_screen.dart`, `exercise_library_screen.dart`, `auth_screen.dart`, `profile_screen.dart`, `onboarding_screen.dart`, etc.
- `lib/widgets/` — reusable UI components such as `recent_workout_card.dart`.

State management

- Uses the `provider` package (ChangeNotifier) to expose state to widgets.
- Providers are created at app root in `main.dart`, ensuring singletons across app lifecycle.

Networking & data flow

- `ApiService` reads token from SharedPreferences, injects `Authorization` header, and handles 401 by clearing token.
- Each resource service maps to backend endpoints and converts JSON ↔ Dart model objects.
- On startup `main()` triggers provider loaders: `UserProvider.loadUser()`, `ExerciseProvider.loadExercises()`, `WorkoutProvider.loadWorkouts()`.

AI flow (client-side)

- `AiApiService.generateWorkoutPlan()` calls the backend `POST /api/ai/generate-plan` with a long timeout (90s).
- The client has a local `_fallbackPlan()` generator so the feature still works if the server AI fails.
- Generated plan -> mapped to exercises in the catalog -> saved via `WorkoutProvider.addTemplate()`; the app now optionally clears existing templates before saving new AI-generated plans.

UI behaviour notes

- Workouts list supports Dismissible-delete per template and a Delete-All action (app bar) to remove templates via `WorkoutProvider.deleteAllTemplates()`.
- Active workout session is stored in-memory until `finishWorkout()` posts the log to the server.
- Error and progress feedback use `SnackBar` and `AlertDialog` throughout.

Frontend run notes

1. Make sure backend is running and reachable from your device/emulator.
2. Install packages: `flutter pub get`.
3. Launch:

```bash
flutter run
```

Platform base URL note: `ApiService` uses `10.0.2.2` for Android emulator and `localhost` on iOS/macOS. If using a physical device, point the backend to an accessible IP and update `.env` or mobile network settings accordingly.

---

## `pubspec.yaml` summary

Key dependencies (see full file `pubspec.yaml`):

- `provider` — state management.
- `shared_preferences` — local token and setup flags.
- `uuid` — client-side generated UUIDs for template IDs.
- `google_fonts`, `intl` — UI and internationalization helpers.
- `flutter_dotenv` — loads `.env` into the app for configuration.
- `http` — HTTP client used by `ApiService`.

Assets

- `.env` file is included as an asset so environment variables can be bundled for debug; secrets should not be committed to source control for production.

---

## Useful commands

Backend

```bash
cd backend/forgefit-backend
composer install
cp .env.example .env
# configure DB and OPENAI_API_KEY in .env
php artisan key:generate
php artisan migrate
php artisan serve --port=8000
```

Frontend

```bash
# at repo root
flutter pub get
flutter run
```

Testing

- Backend: `php artisan test` (or `vendor/bin/phpunit`).
- Frontend: `flutter test`.

---

## Notes & Next steps

- To deploy, provide secure storage for API keys, enable CORS and HTTPS on the API, and configure environment-specific base URLs for the mobile app.
- Consider adding a background synchronization flow for templates/logs and an explicit offline-first cache if you need offline usage.

If you want, I can:

- Generate a Mermaid architecture diagram summarizing the components and data flow.
- Add usage examples for the API with `curl` or an updated Postman collection.
- Create a smaller `README_BACKEND.md` and `README_FRONTEND.md` with step-by-step setup and troubleshooting tips.

---

## Detailed: Database tables, saved data, Flutter connection, and OpenAI prompts

Database tables & key columns
- `users`
  - `id` (unsigned big int, primary)
  - `name`, `nickname`, `email`, `password`
  - `age`, `weight_kg`, `height_cm`, `gender`
  - `goal`, `fitness_level`, `available_equipment` (JSON)
  - `workouts_per_week`, `profile_complete` (boolean)
  - timestamps
- `exercises`
  - `id` (char(36) UUID), `name`, `muscle_group`, `secondary_muscles`
  - `difficulty` (Beginner/Intermediate/Advanced), `equipment`, `instructions`, `form_tips`, `gif_url`
  - `is_custom` (boolean), `user_id` (nullable), timestamps
- `workout_templates`
  - `id` (char(36) UUID), `user_id`, `name`, `description`, `muscle_groups` (JSON), `is_ai_generated` (boolean), timestamps
- `workout_template_exercises`
  - `id` (auto), `template_id`, `exercise_id`, `sets`, `target_reps`, `sort_order`, timestamps
- `workout_logs`
  - `id` (char(36) UUID), `user_id`, `template_id` (nullable), `template_name`, `date` (datetime), `duration_seconds`, `notes`, `muscle_groups` (JSON), timestamps
- `workout_log_exercises`
  - `id` (auto), `log_id`, `exercise_name`, `exercise_id`, `muscle_group`, `sort_order`, `sets` (array of set entries), timestamps
- `set_entries`
  - `id` (auto), `log_exercise_id` or `settable_id`, `weight`, `reps`, `completed` (bool), `sort_order`, timestamps

These tables are implemented by the migrations in `backend/forgefit-backend/database/migrations` and mapped to Eloquent models under `app/Models`.

Saved data examples (payloads)
- Workout template creation (client → `POST /api/templates`):

```json
{
  "name": "4-week Strength Split",
  "description": "AI Generated",
  "muscle_groups": ["Chest","Back","Legs"],
  "exercises": [
    {"exercise_id": "uuid-1", "sets": 4, "target_reps": 8, "sort_order": 0},
    {"exercise_id": "uuid-2", "sets": 3, "target_reps": 10, "sort_order": 1}
  ]
}
```

- Workout log creation (client → `POST /api/logs`):

```json
{
  "template_id": "uuid-template",
  "template_name": "Push Day",
  "date": "2026-05-18T12:00:00Z",
  "duration_seconds": 3600,
  "muscle_groups": ["Chest","Shoulders"],
  "exercises": [
    {
      "exercise_id": "uuid-1",
      "exercise_name": "Barbell Bench Press",
      "muscle_group": "Chest",
      "sets": [
        {"weight": 80, "reps": 8, "completed": true},
        {"weight": 80, "reps": 8, "completed": true}
      ]
    }
  ]
}
```

Flutter connection & API details
- `lib/services/api_service.dart` is the single HTTP client. Key behaviors:
  - `baseUrl` resolves to `http://10.0.2.2:8000/api` on Android emulator, `http://localhost:8000/api` on iOS/macOS.
  - Token stored in `SharedPreferences` under `forgefit_token` and added as `Authorization: Bearer <token>` for authenticated requests.
  - Methods: `get`, `post`, `put`, `delete` with timeouts and a `_handleUnauthorized()` that clears token on 401.
  - To point to a remote backend (physical device or production), change the URL logic in `ApiService.baseUrl` or set up a reverse proxy and `.env` config.

OpenAI prompts and behavior (server-side)
- `backend/app/Services/OpenAiService.php` contains the AI prompt templates and logic. Important points:
  - `planSystemPrompt(User $user)`: Enforces JSON-only output and exact fitness-level exercise filtering: "You are ForgeFit AI coach. When generating a workout plan, return JSON only, use exactly the user's requested workout count, and only use exercises that match the user's exact fitness level. Never mix levels or add extra workouts."
  - `buildChatPrompt(User $user)`: Builds a contextual system prompt for chat that includes recent workout history, total volume, workouts-this-week, streak, equipment, and user profile details. This instructs the chat model to answer conversationally and use the user's recent history.
  - `generatePlan(User $user)`: Constructs a user prompt that includes `workouts_per_week`, equipment, and a list of allowed exercises (from the DB filtered by `difficulty`) and asks the model to return exactly N days in JSON. The backend decodes the model response, attempts to extract JSON if the model wraps it, and then normalizes the plan by ensuring only allowed exercises are kept.
  - `allowedExercisesPrompt()` enumerates up to ~120 exercises matching the user's fitness level and embeds them in the prompt to bias the model to use known exercise names.
  - Models used: `gpt-3.5-turbo` for plan generation, `gpt-4o-mini` for chat in current code — check `OpenAiService.php` for model names.

Notes about AI reliability & fallback
- The server tries to parse JSON from the model; if parsing fails, it attempts to extract a JSON-looking substring. If that still fails, the API returns an error and the client-side `AiApiService` uses a local `_fallbackPlan()` so the feature still works offline or when the AI fails.

Want me to merge these details into separate `README_BACKEND.md` and `README_FRONTEND.md` files too? I can create them and link them from the main README.

**_ End of README _**
