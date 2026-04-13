<?php

namespace App\Providers;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\ServiceProvider;
use Throwable;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        if (config('database.default') !== 'sqlite') {
            return;
        }

        $databasePath = config('database.connections.sqlite.database');

        if (!$databasePath) {
            return;
        }

        if (!str_starts_with($databasePath, DIRECTORY_SEPARATOR)) {
            $databasePath = base_path($databasePath);
        }

        if (!file_exists($databasePath)) {
            return;
        }

        try {
            DB::statement('PRAGMA journal_mode=WAL;');
            DB::statement('PRAGMA synchronous=NORMAL;');
        } catch (Throwable $e) {
            //
        }
    }
}