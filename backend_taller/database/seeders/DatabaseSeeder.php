<?php

namespace Database\Seeders;

use App\Models\Provider;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        Provider::insert([
            [
                'name' => 'Seguros Bolívar',
                'code' => 'BOLIVAR',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Sura',
                'code' => 'SURA',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Allianz',
                'code' => 'ALLIANZ',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}