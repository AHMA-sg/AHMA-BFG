Overview: Webhooks
Learn how webhooks work with Ultravox and get started with real-time notifications.

Webhooks provide a powerful way to receive real-time notifications about events in your Ultravox Realtime account. Instead of repeatedly polling our API to check for updates, webhooks push event data directly to your application as soon as something happens.
When you configure a webhook in Ultravox, we’ll send an HTTP POST request to your specified URL whenever a subscribed event occurs. This allows your application to react immediately to important events like call starts, call ends, etc. Your server needs to respond with a 2xx to confirm receipt. If delivery fails, we will retry delivery.
​
Getting Started
To start using webhooks with Ultravox:
Set up an endpoint: Create a URL on a server that can receive POST requests.
Create a webhook: Use the Ultravox API to register the URL that will receive webhook events and select events you want to receive.
Handle events: Process incoming webhook data in your application.
Secure your webhook: Implement signature verification for security (recommended).
​
Webhook Payload Structure
All webhooks follow a consistent structure and return the event and details about the call.
{
  "event": {event_name},
  "call": {call_object}
}
See Event Payload Reference.
​
Best Practices
Respond Quickly: Return a 2xx status code (we recommend 204) as soon as you receive the webhook. Process the data asynchronously if needed.
Handle Duplicates: In rare cases, you might receive the same webhook twice. Make your processing idempotent.
Implement Security: Always verify webhook signatures to ensure requests are from Ultravox Realtime.
Monitor Failures: Keep track of failed webhook deliveries and have a backup plan to retrieve missed data via our API.
Use HTTPS: Always use HTTPS endpoints for webhooks to protect sensitive data in transit.
​
Keep Building
Learn about all Available Webhooks you can subscribe to.
Learn about webhook errors and our retry strategy.
Implement Webhook Security to protect your endpoints.
Check out our API reference for webhook management endpoints.

Available Webhooks
Complete reference of all webhook events available in Ultravox.

Ultravox offers several webhook events that you can subscribe to for real-time notifications. Each event provides detailed information about what happened in your account.
​
Available Events
The following events are available and can be specified when creating or updating a webhoook.
event	description
call.started	Fires when a call is created.
call.joined	Fires when a client connects to your call.
call.ended	Fires when a call ends.
call.billed	Fires when a call is billed.
​
call.started
Fires when a call is created.
If you create calls directly using either the Create Agent Call or Create Call API, you likely won’t need this event as a 201 response to your call creation request is equivalent.
The call.started event is most useful with telephony integrations where you’ve allowed calls to be created on your behalf either in response to qualified SIP INVITEs or verified requests from your telephony provider (Twilio, Telnyx, or Plivo).
​
call.joined
Fires when a client connects to your call.
Useful if you need to keep track of live calls or for monitoring deltas in timing from call creation.
​
call.ended
Fires when a call ends.
The call’s messages are now immutable because the call is over. However, billing information may not be available yet (in particular for SIP calls, where the SIP session could be ongoing — see call.billed). This event is also sent for unjoined calls when their join timeout is reached.
​
call.billed
Fires when a call is billed.
Billing information will always be available. Typically you’ll only want one of call.ended or call.billed. If you aren’t using SIP or don’t need billing details for your integration, call.ended may be preferable.
​
Event Payload Reference
All webhooks follow a consistent structure. The payload always includes:
event: The type of event that triggered the webhook.
call: Complete call object matching our API response format.
Generic Structure
Example Payload: call.started
{
  "event": {event_name},
  "call": {call_object}
}
​
Event Name
The event field contains the exact event name you subscribed to:
"call.started"
"call.ended"
"call.joined"
"call.billed"
​
Call Object
The call object contains the complete call definition, identical to what you’d receive from the Get Call API endpoint. This ensures consistency across your application whether you’re receiving webhook data or making API requests.
Key call object fields:
callId: Unique call identifier
created: Timestamp when call was created
joined: Timestamp when call was joined
ended: Timestamp when call was ended
shortSummary: Short summary of the call
metadata: Custom metadata you’ve associated with the call
See the Call definition schema for the complete list of fields.
​
Webhook Configuration
When creating or updating a webhook, specify which events you want to receive:
curl -X POST https://api.ultravox.ai/api/webhooks \
  -H "X-API-Key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-app.com/webhooks/ultravox",
    "events": ["call.started", "call.ended"],
    "secrets": ["your-webhook-secret"]
  }'
​
HTTP Requirements
Your webhook endpoint must meet these requirements:
Accept POST Requests: All webhooks are sent as HTTP POST requests.
Return 2xx Status: Return any 2xx status code (we recommend 204) to acknowledge receipt.
Respond Quickly: Respond quickly to avoid timeouts.
Handle JSON: Parse the JSON payload from the request body.
Example: Handling Webhook Events
// Express.js webhook handler example
app.post('/ultravox-webhook', (req, res) => {
  const event = req.body;
  
  switch (event.event) {
    case 'call.started':
      console.log('Call started:', event.call.callId);
      // Initialize any required resources
      break;
      
    case 'call.joined':
      console.log('User joined call:', event.call.callId);
      // Update UI, start monitoring, etc.
      break;
      
    case 'call.ended':
      console.log('Call ended:', event.call.callId, 'Reason:', event.call.endReason);
      // Clean up resources, analyze results, etc.
      break;
    
    case 'call.billed':
      console.log('Call billed:', event.call.callId);
      // Update customer invoice, etc.
      break;
  }
  
  res.status(200).send('OK');
});
​
Error Responses
If your endpoint returns a non-2xx status code (e.g. 4xx or 5xx), Ultravox will retry delivery. See Error Handling & Retries for more details.
​
Testing Webhooks
During development, consider using tools like:
ngrok: Expose local development servers to receive webhooks
webhook.site: Test webhook payloads without writing code
Postman: Mock webhook endpoints for testing
Remember that webhook events reflect real activity in your Ultravox account, so test carefully to avoid processing duplicate or test data in production systems.

Error Handling & Retries
Understand how Ultravox automatically retries failed webhook deliveries with exponential backoff to ensure reliable event notifications.

​
Retrying Failed Webhook Event Deliveries
If your webhook endpoint is temporarily unavailable or returns an error status code (e.g. 4xx or 5xx), Ultravox will automatically retry delivery using an exponential backoff strategy.
We’ll make up to 10 retry attempts over several hours as follows:
First retry will occur approximately 30 seconds later.
Subsequent retries will double the retry interval. (e.g. second retry again after 1m, third retry after 2m, etc.)
Total of 10 retries.
For permanent failures or extended downtime, you can always use our REST API to retrieve information about any calls/events you may have missed.
​
Keep Building
Learn about all Available Webhooks you can subscribe to
Implement Webhook Security to protect your endpoints
Check out our API reference for webhook management endpoints

Securing Webhooks
Learn how to verify webhook authenticity and protect your endpoints from malicious requests.

Webhook security is crucial for protecting your application from malicious requests and ensuring that you only process authentic notifications from Ultravox. This guide covers how to implement proper webhook verification.
​
Why Webhook Security Matters
Without proper verification, anyone could send fake webhook requests to your endpoint, potentially:
Triggering unauthorized actions in your application or bypassing your business logic
Corrupting your data with false information
Overwhelming your system with spam requests
​
How Ultravox Secures Webhooks
Ultravox uses HMAC-SHA256 signatures to ensure webhook authenticity. Each webhook request includes cryptographic proof that:
The request came from Ultravox
The payload hasn’t been tampered with
The request is recent (not a replay attack)
​
Securing Your Webhooks
You can optionally choose to secure your webhooks with a key. When creating a webhook, a secret key is automatically generated for you or you can choose to provide your own secret. You can update or patch your webhooks to change secrets in the event of a leak or as part of regular key rotation.
Each time your server receives an incoming webhook from Ultravox here’s how you can ensure the webhook was sent by Ultravox and hasn’t been tampered with:
1
Timestamp Verification

Each incoming webhook request includes a X-Ultravox-Webhook-Timestamp header with the time the webhook was sent.
Verify that this timestamp is recent (e.g. within the last minute) to prevent replay attacks.
2
Signature Verification

Ultravox signs each webhook using HMAC-SHA256.
The signature is included in the X-Ultravox-Webhook-Signature header.
To verify the signature:
Concatenate the raw request body with the timestamp.
Create an HMAC-SHA256 hash of this concatenated string using your webhook secret as the key.
Compare this hash with the provided signature.
Verifying Webhook Signature
import datetime
import hmac

request_timestamp = request.headers["X-Ultravox-Webhook-Timestamp"]
if datetime.datetime.now() - datetime.datetime.fromisoformat(request_timestamp) > datetime.timedelta(minutes=1):
  raise RuntimeError("Expired message")
expected_signature = hmac.new(WEBHOOK_SECRET.encode(), request.content + request_timestamp.encode(), "sha256").hexdigest()
for signature in request.headers["X-Ultravox-Webhook-Signature"].split(","):
  if hmac.compare_digest(signature, expected_signature):
    break  # Valid signature
else:
  raise RuntimeError("Message or timestamp was tampered with")
3
Multiple Signatures

The X-Ultravox-Webhook-Signature header may contain multiple signatures separated by commas.
This allows for key rotation without downtime.
Your code should check if any of the provided signatures match your computed signature.
​
Testing
During development, you can test your webhook security implementation by:
Creating a test webhook with a known secret
Manually crafting webhook requests with correct signatures
Verifying that invalid signatures are properly rejected
Testing with expired timestamps
By implementing these checks, you ensure that only authentic, recent, and unmodified webhooks from Ultravox are processed by your system. Remember to store your webhook secret securely and never expose it in client-side code or public repositories.

