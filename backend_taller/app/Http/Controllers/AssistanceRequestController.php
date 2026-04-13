<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessAssistanceRequest;
use App\Models\AssistanceRequest;
use Illuminate\Http\Request;

class AssistanceRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = AssistanceRequest::with('provider')->orderByDesc('id');

        if ($request->has('status') && $request->status !== '') {
            $query->where('status', $request->status);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'client_name' => 'required|string|max:255',
            'vehicle_plate' => 'required|string|max:20',
            'location' => 'required|string|max:255',
            'description' => 'required|string',
            'provider_id' => 'required|exists:providers,id',
        ]);

        $assistanceRequest = AssistanceRequest::create([
            'client_name' => $validated['client_name'],
            'vehicle_plate' => $validated['vehicle_plate'],
            'location' => $validated['location'],
            'description' => $validated['description'],
            'provider_id' => $validated['provider_id'],
            'status' => 'pending',
            'assigned_technician' => null,
        ]);

        ProcessAssistanceRequest::dispatch($assistanceRequest->id);

        return response()->json([
            'message' => 'Solicitud recibida y en proceso',
            'id' => $assistanceRequest->id,
            'status' => $assistanceRequest->status,
        ], 202);
    }

    public function show(string $id)
    {
        $assistanceRequest = AssistanceRequest::with('provider')->findOrFail($id);

        return response()->json($assistanceRequest);
    }

    public function assignTechnician(Request $request, string $id)
    {
        $validated = $request->validate([
            'assigned_technician' => 'required|string|max:255',
        ]);

        $assistanceRequest = AssistanceRequest::findOrFail($id);

        $assistanceRequest->update([
            'assigned_technician' => $validated['assigned_technician'],
        ]);

        return response()->json([
            'message' => 'Técnico asignado correctamente',
            'request' => $assistanceRequest->load('provider'),
        ]);
    }
}