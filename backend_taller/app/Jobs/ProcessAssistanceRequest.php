<?php

namespace App\Jobs;

use App\Models\AssistanceRequest;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcessAssistanceRequest implements ShouldQueue
{
    use Queueable;

    public function __construct(public int $assistanceRequestId)
    {
    }

    public function handle(): void
    {
        $request = AssistanceRequest::find($this->assistanceRequestId);

        if (!$request) {
            return;
        }

        $request->update([
            'status' => 'processing',
        ]);

        sleep(30);

        $request->update([
            'status' => 'completed',
            'processed_at' => now(),
        ]);
    }
}