# ForgeFit Laravel 11 API

This folder contains scaffold files for a Laravel 11 REST API for the ForgeFit app.

Quick setup (on machine with PHP 8.2+, Composer, MySQL 8):

```bash
# create project
composer create-project laravel/laravel:^11 forgefit-api
cd forgefit-api
# copy scaffold files from ../backend into this project's directories (migrations, app, config, routes, etc.)
# then install OpenAI PHP client
composer require openai-php/client

# update .env per README and run migrations
php artisan key:generate
# Edit .env: DB_CONNECTION=mysql, DB_HOST, DB_PORT, DB_DATABASE=forgefit, DB_USERNAME=root, DB_PASSWORD=your_password
# Add OPENAI_API_KEY in .env
php artisan migrate
php artisan db:seed --class=ExerciseSeeder
php artisan serve
```

Notes:
- Ensure `config/database.php` default connection is `mysql`.
- AppServiceProvider boot() includes `Schema::defaultStringLength(191);`.
- All provided migration files use `utf8mb4` charset and use MySQL native JSON columns where requested.

See the `routes/api.php` file for API endpoints and controllers under `app/Http/Controllers`.
# FOrgeFit-BACKEND
# FOrgeFit-BACKEND
