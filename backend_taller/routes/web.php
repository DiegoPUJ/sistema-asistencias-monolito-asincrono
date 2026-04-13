<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AssistanceRequestController;
use App\Models\Provider;

Route::get('/providers', function () {
    return response()->json(Provider::orderBy('name')->get());
});

Route::get('/assistance-requests', [AssistanceRequestController::class, 'index']);
Route::post('/assistance-requests', [AssistanceRequestController::class, 'store']);
Route::get('/assistance-requests/{id}', [AssistanceRequestController::class, 'show']);
Route::patch('/assistance-requests/{id}/assign', [AssistanceRequestController::class, 'assignTechnician']);