<?php

namespace App\Http\Controllers;

use App\Models\Contact;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class ContactController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        // 1. Validate submitted data
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',

            'mobile_number' => [
                'required',
                'regex:/^[0-9]{10}$/',
            ],

            'email' => 'required|email|max:255',

            'city' => 'required|string|max:255',
        ]);

        try {
            // 2. Save enquiry in database
            $contact = Contact::create([
                'full_name' => trim($validated['full_name']),
                'mobile_number' => trim($validated['mobile_number']),
                'email' => trim($validated['email']),
                'city' => trim($validated['city']),
            ]);

            // 3. Send email
            $recipient = env(
                'CONTACT_RECIPIENT',
                'majesticdigital01@gmail.com'
            );

            Mail::raw(
                "New Mount Castle Website Enquiry\n\n" .
                "Full Name: " . $contact->full_name . "\n" .
                "Mobile Number: " . $contact->mobile_number . "\n" .
                "Email: " . $contact->email . "\n" .
                "City: " . $contact->city . "\n\n" .
                "Submitted from Mount Castle website.",
                function ($message) use ($recipient, $contact) {
                    $message
                        ->to($recipient)
                        ->subject(
                            'New Mount Castle Enquiry - ' .
                            $contact->full_name
                        );
                }
            );

            // 4. Return success response
            return response()->json([
                'success' => true,
                'message' => 'Thank you! We will contact you shortly.',
                'data' => [
                    'id' => $contact->id,
                ],
            ], 201);

        } catch (\Throwable $exception) {
            // Save error in Laravel logs
            Log::error('Contact enquiry failed', [
                'error' => $exception->getMessage(),
            ]);

            // Return error response
            return response()->json([
                'success' => false,
                'message' => 'Unable to submit your enquiry. Please try again later.',
            ], 500);
        }
    }
}