# ForgeFit API Endpoints

Base URL: `http://127.0.0.1:8000/api`

## Auth
- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`
- `POST /auth/update-profile`

## Exercises
- `GET /exercises`
- `POST /exercises`
- `DELETE /exercises/{id}`

## Templates
- `GET /templates`
- `POST /templates`
- `DELETE /templates/{id}`

## Logs
- `GET /logs`
- `POST /logs`
- `DELETE /logs/{id}`
- `GET /logs/stats`
- `GET /logs/exercise-progress/{exercise_id}`

## AI
- `POST /ai/chat`
- `POST /ai/generate-plan`
- `POST /ai/overload-suggestion`
- `POST /ai/missing-muscles`
- `POST /ai/form-advice`
