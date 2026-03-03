# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AHMA is a caretaker app aiming to support caregivers emotionally, help them navigate Singapore's complex support system, and by making responsive decisions to help caretakers with simple tasks. It is built as a Flutter application that integrates with Ultravox, a voice AI platform for building real-time conversational agents. The app is currently in early stages with the default Flutter template structure.

## Development Commands

### Running the App
```bash
# Run on default device
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device_id>

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Format code
flutter format .

# Format a specific file
flutter format lib/main.dart
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build iOS app
flutter build ios

# Build for web
flutter build web

# Build for Linux
flutter build linux

# Build for macOS
flutter build macos

# Build for Windows
flutter build windows
```

## Architecture

### Two-Layer Architecture

AHMA uses a two-layer architecture:

1. **Flutter App (Layer 1)**: Real-time voice conversations with fast responses via Ultravox
2. **Agentic Backend (Layer 2)**: Asynchronous data synthesis, tool execution, and resource management

**POC Scope**: Voice call only. Focus on Ultravox integration with stage-based workflow.

### Flutter App Structure

```
lib/
├── core/                          # Core utilities, constants, config
│   ├── config/
│   │   ├── env_config.dart        # API keys (Ultravox, backend, Firebase)
│   │   └── audio_config.dart      # Audio settings (48000 Hz, buffer size)
│   ├── constants/
│   │   ├── api_constants.dart     # API endpoints
│   │   └── corpus_ids.dart        # RAG corpus IDs (Caring.sg, Mindfull, CWA)
│   ├── error/
│   │   ├── exceptions.dart        # Custom exceptions
│   │   └── failures.dart          # Failure types
│   └── network/
│       └── dio_client.dart        # Base HTTP client with interceptors
│
├── data/                          # Data layer
│   ├── models/
│   │   ├── ultravox/              # Ultravox models (Agent, Call, Tool, Message)
│   │   ├── backend/               # Backend models (Update, Action, Resource)
│   │   └── user/                  # User models (CaregiverProfile, StressAssessment)
│   ├── repositories/
│   │   ├── ultravox_repository_impl.dart
│   │   └── backend_repository_impl.dart
│   └── datasources/
│       ├── ultravox_api.dart      # Ultravox REST API client
│       ├── ultravox_rtc.dart      # WebRTC connection manager
│       ├── backend_api.dart       # Backend API client
│       └── webhook_handler.dart   # Webhook receiver
│
├── domain/                        # Business logic layer
│   ├── entities/                  # Business entities
│   ├── repositories/              # Repository interfaces
│   └── usecases/
│       ├── voice/
│       │   ├── start_voice_call.dart
│       │   ├── end_voice_call.dart
│       │   └── assess_caregiver_state.dart
│       ├── backend/
│       │   ├── send_transcript.dart
│       │   └── process_backend_update.dart
│       └── agent/
│           └── configure_ahma_agent.dart
│
└── presentation/                  # UI layer
    ├── screens/
    │   ├── home_screen.dart       # Main screen (voice call entry)
    │   ├── voice_call_screen.dart # Active call UI
    │   ├── updates_screen.dart    # Backend actions display
    │   └── profile_screen.dart    # User profile management
    ├── widgets/
    │   ├── voice_button.dart
    │   ├── call_status.dart
    │   ├── transcript_view.dart
    │   ├── update_card.dart
    │   ├── stress_indicator.dart
    │   └── stage_progress.dart
    └── providers/                 # State management (Riverpod)
        ├── call_provider.dart
        ├── backend_provider.dart
        └── auth_provider.dart
```

### Core Components

#### Ultravox Integration
- **UltravoxApiClient** (`ultravox_api.dart`): REST API for agents, calls, tools, corpora
- **WebRTCManager** (`ultravox_rtc.dart`): Real-time audio connection (48000 Hz, s16le PCM)
- **AgentConfigurator** (`configure_ahma_agent.dart`): Sets up AHMA agent with:
  - Stage-based system prompt (Assess → Support → Evaluate)
  - RAG corpora (Caring.sg, Mindfull, CWA)
  - Custom tools (`queryCorpus`, `sendToBackend`)

#### Backend Integration
- **BackendApiClient** (`backend_api.dart`): HTTP client for agentic backend
- **WebhookHandler** (`webhook_handler.dart`): Receives async updates via webhooks
- **TranscriptSender** (`send_transcript.dart`): Sends conversation transcript after call ends

#### State Management (Riverpod)
- **CallProvider**: Active call state, stage tracking (1: Assess, 2: Support, 3: Evaluate), transcript
- **BackendProvider**: Webhook updates, pending actions, resources, action plans
- **AuthProvider**: Firebase Auth, caregiver profile, care recipient info

### Key Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # HTTP & Networking
  dio: ^5.4.0                      # HTTP client with interceptors

  # WebRTC for Ultravox
  flutter_webrtc: ^0.9.48          # Real-time audio

  # State Management
  flutter_riverpod: ^2.4.9         # Modern state management
  riverpod_annotation: ^2.3.3

  # Data Models
  freezed_annotation: ^2.4.1       # Immutable models
  json_annotation: ^4.8.1          # JSON serialization

  # Configuration
  flutter_dotenv: ^5.1.0           # Environment variables

  # Authentication
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3           # User authentication

  # Permissions
  permission_handler: ^11.1.0      # Audio permissions

  # Storage
  shared_preferences: ^2.2.2       # Local storage

  # Notifications
  flutter_local_notifications: ^16.3.0

  # Utilities
  intl: ^0.18.1                    # Date/time formatting

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Code Generation
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  riverpod_generator: ^2.3.9
```


### Data Flow

#### Voice Call Flow (Real-time)
```
User taps "Start Voice Call" on Home Screen
    ↓
CallProvider.startCall()
    ↓
ConfigureAhmaAgent use case creates/retrieves agent
    ↓
UltravoxApiClient.createCall(agentId, userContext)
    ↓
WebRTCManager.connect(joinUrl)
    ↓
┌─────────────────────────────────────────────┐
│ Real-time Voice Conversation                 │
│                                              │
│ Stage 1: ASSESS                              │
│ - Agent asks about caregiver's state         │
│ - Detects stress level (regular/elevated)   │
│                                              │
│ Stage 2: SUPPORT                             │
│ - Emotional support conversation             │
│ - queryCorpus tool → Caring.sg/Mindfull/CWA │
│ - sendToBackend tool → trigger async actions│
│                                              │
│ Stage 3: EVALUATE                            │
│ - Summarize conversation                     │
│ - Confirm next steps                         │
│ - Prepare to end call                        │
└─────────────────────────────────────────────┘
    ↓
User ends call or agent triggers hangUp
    ↓
CallProvider captures transcript
    ↓
SendTranscript use case → POST /api/transcript
    ↓
Backend queues processing
    ↓
CallProvider updates UI (call ended)
```

#### Backend Update Flow (Async via Webhooks)
```
Backend processes transcript
    ↓
ADK agent analyzes conversation
    ↓
Executes tools:
  - Google Calendar API (reminders, mental health blocks)
  - RAG query (additional resources)
  - Action plan generation
    ↓
Backend sends webhook to Flutter app
    ↓
WebhookHandler receives POST request
    ↓
Verifies HMAC signature
    ↓
BackendProvider.processUpdate(webhookData)
    ↓
UI updates:
  - Push notification
  - Updates screen shows new actions
  - Action plan displayed
```

### Stage-Based Workflow Implementation

The AHMA agent follows a three-stage conversation workflow:

#### Stage 1: Assess Current State (Duration: ~2-3 minutes)

**Objectives:**
- Detect caregiver's emotional state
- Identify stress level (regular vs. elevated)
- Understand immediate needs

**System Prompt Instructions:**
```
You are AHMA, a compassionate voice assistant for caregivers in Singapore.

STAGE 1 - ASSESS (Current conversation stage):
Start by warmly greeting the caregiver and asking how they're doing today.
Listen for signs of stress, exhaustion, or overwhelm in their responses.
Ask 2-3 gentle questions to understand:
- How they're feeling emotionally
- Recent challenges in caregiving
- Whether they need immediate support

Classify stress level:
- REGULAR: Caregiver is coping, may need information/resources
- ELEVATED: Signs of burnout, exhaustion, emotional distress

Move to Stage 2 once you understand their current state.
```

**Implementation:**
- `lib/domain/usecases/voice/assess_caregiver_state.dart`
- CallProvider tracks current stage
- UI shows "Assessing..." with blue indicator

#### Stage 2: Provide Support (Duration: ~5-8 minutes)

**Objectives:**
- Offer emotional support through empathetic conversation
- Query RAG corpora for relevant resources
- Send tool requests to backend for async actions

**System Prompt Instructions:**
```
STAGE 2 - SUPPORT (Current conversation stage):
Based on the caregiver's state, provide targeted support:

For ELEVATED stress:
1. Acknowledge their feelings with empathy
2. Offer immediate coping strategies (breathing, taking breaks)
3. Use queryCorpus tool to find mental health resources from Mindfull corpus
4. Use sendToBackend tool to schedule mental health time on their calendar

For REGULAR stress:
1. Provide information and practical guidance
2. Use queryCorpus tool to find relevant resources from Caring.sg or CWA corpus
3. Answer specific questions about caregiving support programs

Keep responses concise and conversational. Don't overwhelm with too much information.
Move to Stage 3 when the caregiver feels heard and has received helpful resources.
```

**RAG Corpus Usage:**
- **Caring.sg corpus**: General caregiving resources, financial aid, respite care
- **Mindfull corpus**: Mental health support, stress management, counseling
- **CWA corpus**: Support groups, training programs, caregiver benefits

**Tool Integration:**
```dart
// queryCorpus tool configuration
{
  "toolName": "queryCorpus",
  "parameterOverrides": {
    "corpus_id": "{{corpusId}}",  // Dynamically set based on need
    "max_results": 3
  }
}

// sendToBackend tool (custom)
{
  "temporaryTool": {
    "modelToolName": "sendToBackend",
    "description": "Send a tool request to the backend for async execution",
    "dynamicParameters": [
      {
        "name": "toolName",
        "location": "PARAMETER_LOCATION_BODY",
        "schema": {"type": "string"},
        "required": true
      },
      {
        "name": "parameters",
        "location": "PARAMETER_LOCATION_BODY",
        "schema": {"type": "object"},
        "required": true
      }
    ],
    "http": {
      "baseUrlPattern": "{{backendUrl}}/api/tool-request",
      "httpMethod": "POST"
    }
  }
}
```

**Implementation:**
- CallProvider updates stage to "Supporting"
- UI shows "Providing support..." with green indicator
- Transcript view displays agent's resource recommendations

#### Stage 3: Evaluate & Next Steps (Duration: ~2-3 minutes)

**Objectives:**
- Summarize conversation
- Confirm understanding of next steps
- End call gracefully

**System Prompt Instructions:**
```
STAGE 3 - EVALUATE (Current conversation stage):
Wrap up the conversation:

1. Summarize what you've discussed (2-3 sentences)
2. Confirm the resources or support you've provided
3. Let them know that:
   - They'll receive a summary of resources via the app
   - Calendar reminders will be set if needed
   - An action plan will be generated
4. Ask if there's anything else they need right now
5. End with encouragement and remind them help is available anytime

Use a warm, supportive closing. Make them feel heard and supported.
```

**Implementation:**
- CallProvider updates stage to "Evaluating"
- UI shows "Wrapping up..." with purple indicator
- Agent triggers hangUp tool or user ends call
- Transcript sent to backend automatically

### RAG Corpus Setup

Three RAG corpora must be configured for Singapore caregiver support:

#### 1. Caring.sg Corpus

**Via Ultravox Web App:**
1. Navigate to RAG section
2. Create new collection: "AHMA Corpora"
3. Create source: "Caring.sg Resources"
4. Add web URLs to crawl:
   - https://www.caring.sg/
   - https://www.caring.sg/caregivers-resources
   - https://www.caring.sg/financial-assistance
5. Upload PDFs: Caregiving guides, respite care brochures

**Via API:**
```bash
# Create corpus
curl -X POST https://api.ultravox.ai/api/corpora \
  -H "X-API-Key: $ULTRAVOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Caring.sg Resources",
    "description": "General caregiving resources and support in Singapore"
  }'

# Create web source
curl -X POST https://api.ultravox.ai/api/corpora/{corpus_id}/sources \
  -H "X-API-Key: $ULTRAVOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Caring.sg Website",
    "web": {
      "startUrls": ["https://www.caring.sg/"]
    }
  }'
```

**Store corpus ID:**
```dart
// lib/core/constants/corpus_ids.dart
class CorpusIds {
  static const String caringSg = 'corpus_abc123';
  static const String mindfull = 'corpus_def456';
  static const String cwa = 'corpus_ghi789';
}
```

#### 2. Mindfull Corpus

Similar setup for mental health resources:
- Web URLs: Mindfull website, mental health guides
- Documents: Stress management PDFs, coping strategies

#### 3. CWA (Caregivers Alliance) Corpus

- Web URLs: CWA website, program pages
- Documents: Training materials, support group info

### Backend Integration

#### Agentic Backend Server Architecture

**Stack (to be built):**
- **Framework**: FastAPI (Python) or Node.js/Express
- **Agents**: Google Agent Development Kit (ADK)
- **Graph DB**: Neo4j (caregiver relationships)
- **Vector DB**: Pinecone/Chroma (additional RAG)
- **Queue**: Redis/Cloud Tasks (async jobs)
- **Hosting**: Google Cloud Run / AWS Lambda

**API Endpoints:**
```
POST /api/transcript
  - Receives call transcript from Flutter
  - Queues for ADK agent processing
  - Returns 202 Accepted

POST /api/tool-request
  - Receives tool requests during Ultravox calls
  - Queues tool execution
  - Returns acknowledgment

POST /api/webhook/register
  - Registers Flutter app webhook endpoint
  - Stores endpoint for sending updates
  - Returns registration confirmation

GET /api/updates/{userId}
  - Polling fallback for webhook failures
  - Returns pending updates for user

GET /api/resources
  - Fetches curated caregiver resources
  - Filtered by category/need
```

#### Webhook Integration

**Flutter Webhook Receiver:**
```dart
// lib/data/datasources/webhook_handler.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:crypto/crypto.dart';

class WebhookHandler {
  final BackendProvider backendProvider;
  final String webhookSecret;

  Future<Response> handleWebhook(Request request) async {
    // 1. Read raw body
    final body = await request.readAsString();

    // 2. Verify HMAC signature
    final signature = request.headers['x-ahma-signature'];
    final timestamp = request.headers['x-ahma-timestamp'];

    if (!_verifySignature(body, timestamp, signature)) {
      return Response.forbidden('Invalid signature');
    }

    // 3. Check timestamp (prevent replay attacks)
    if (!_isRecentTimestamp(timestamp)) {
      return Response.forbidden('Expired request');
    }

    // 4. Parse webhook payload
    final update = BackendUpdate.fromJson(jsonDecode(body));

    // 5. Process update
    await backendProvider.processUpdate(update);

    // 6. Return 204 No Content
    return Response(204);
  }

  bool _verifySignature(String body, String timestamp, String signature) {
    final message = '$body$timestamp';
    final hmac = Hmac(sha256, utf8.encode(webhookSecret));
    final digest = hmac.convert(utf8.encode(message));
    return digest.toString() == signature;
  }
}
```

**Backend Webhook Sender:**
```python
# backend/services/webhook_service.py
import hmac
import hashlib
import httpx
from datetime import datetime

async def send_webhook(user_id: str, update_data: dict):
    webhook_url = await get_user_webhook_url(user_id)
    webhook_secret = settings.WEBHOOK_SECRET

    timestamp = datetime.utcnow().isoformat()
    body = json.dumps(update_data)
    message = f"{body}{timestamp}"

    signature = hmac.new(
        webhook_secret.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()

    headers = {
        'Content-Type': 'application/json',
        'X-Ahma-Signature': signature,
        'X-Ahma-Timestamp': timestamp
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            webhook_url,
            json=update_data,
            headers=headers,
            timeout=10.0
        )

    if response.status_code != 204:
        # Retry logic here
        await queue_webhook_retry(user_id, update_data)
```

### Security Considerations

#### API Key Management
```dart
// .env file (NEVER commit to git)
ULTRAVOX_API_KEY=uvx_api_key_here
BACKEND_API_KEY=backend_key_here
FIREBASE_API_KEY=firebase_key_here

// lib/core/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get ultravoxApiKey => dotenv.env['ULTRAVOX_API_KEY']!;
  static String get backendApiKey => dotenv.env['BACKEND_API_KEY']!;
  static String get backendBaseUrl => dotenv.env['BACKEND_BASE_URL']!;
}

// main.dart
Future<void> main() async {
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}
```

#### .gitignore
```
# Environment
.env
.env.local
.env.production

# Secrets
secrets/
*.key
*.pem
```

#### Firebase Authentication
```dart
// lib/presentation/providers/auth_provider.dart
@riverpod
class Auth extends _$Auth {
  @override
  Future<User?> build() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    state = AsyncValue.data(userCredential.user);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }
}
```

### Common Development Patterns

#### 1. Creating the AHMA Agent

```dart
// lib/domain/usecases/agent/configure_ahma_agent.dart
class ConfigureAhmaAgent {
  final UltravoxRepository repository;

  Future<Agent> execute(CaregiverProfile profile) async {
    final systemPrompt = _buildSystemPrompt(profile);
    final tools = _buildTools();

    return repository.createAgent(
      name: 'AHMA Voice Assistant',
      systemPrompt: systemPrompt,
      voice: 'Jessica',  // Female, warm voice
      temperature: 0.4,  // Consistent, empathetic responses
      tools: tools,
      firstSpeakerSettings: {
        'agent': {
          'text': 'Hello ${profile.firstName}, this is AHMA. How are you doing today?'
        }
      },
    );
  }

  String _buildSystemPrompt(CaregiverProfile profile) {
    return '''
You are AHMA, a compassionate voice assistant for caregivers in Singapore.

CAREGIVER CONTEXT:
- Name: ${profile.firstName}
- Caring for: ${profile.careRecipient.relationship} (${profile.careRecipient.condition})
- Caregiver type: ${profile.caregiverType}
- Recent stress level: ${profile.lastStressLevel}

CONVERSATION STAGES:
[Stage 1, 2, 3 instructions as detailed above...]

Remember: Be warm, empathetic, and concise. Focus on emotional support first, practical guidance second.
    ''';
  }

  List<Tool> _buildTools() {
    return [
      Tool.queryCorpus(
        corpusIdOverride: null,  // Will set dynamically
        maxResults: 3,
      ),
      Tool.custom(
        name: 'sendToBackend',
        description: 'Send async tool request to backend',
        // ... configuration
      ),
      Tool.hangUp(),
    ];
  }
}
```

#### 2. Starting a Voice Call

```dart
// lib/presentation/providers/call_provider.dart
@riverpod
class Call extends _$Call {
  @override
  CallState build() => const CallState.idle();

  Future<void> startVoiceCall() async {
    state = const CallState.connecting();

    try {
      // 1. Get user profile
      final profile = await ref.read(authProvider.future);

      // 2. Configure/retrieve AHMA agent
      final agent = await ref.read(configureAhmaAgentProvider(profile).future);

      // 3. Create call
      final call = await _repository.createCall(
        agentId: agent.id,
        metadata: {
          'userId': profile.id,
          'caregiverType': profile.caregiverType,
        },
      );

      // 4. Connect WebRTC
      await _webrtcManager.connect(call.joinUrl);

      // 5. Update state
      state = CallState.active(
        callId: call.id,
        stage: CallStage.assess,
        transcript: [],
      );
    } catch (e) {
      state = CallState.error(e.toString());
    }
  }

  Future<void> endCall() async {
    final currentState = state;
    if (currentState is! ActiveCallState) return;

    // 1. End WebRTC connection
    await _webrtcManager.disconnect();

    // 2. Get final transcript
    final transcript = await _repository.getCallTranscript(currentState.callId);

    // 3. Send to backend
    await ref.read(sendTranscriptProvider).execute(
      userId: currentState.userId,
      callId: currentState.callId,
      transcript: transcript,
      detectedStressLevel: currentState.stressLevel,
    );

    // 4. Update state
    state = CallState.ended(transcript: transcript);
  }
}
```

#### 3. Processing Backend Webhook

```dart
// lib/domain/usecases/backend/process_backend_update.dart
class ProcessBackendUpdate {
  final BackendRepository repository;
  final NotificationService notifications;

  Future<void> execute(BackendUpdate update) async {
    switch (update.type) {
      case UpdateType.calendarEvent:
        await _handleCalendarEvent(update.data);
        break;
      case UpdateType.resourceRecommendation:
        await _handleResourceRecommendation(update.data);
        break;
      case UpdateType.actionPlan:
        await _handleActionPlan(update.data);
        break;
    }

    // Show notification to user
    await notifications.show(
      title: update.title,
      body: update.message,
      payload: update.id,
    );
  }

  Future<void> _handleCalendarEvent(Map<String, dynamic> data) async {
    final event = CalendarEvent.fromJson(data);
    // Store event, update UI
    await repository.saveCalendarEvent(event);
  }

  // ... other handlers
}
```

### Debugging & Development Tips

#### Viewing Ultravox Call Logs
```dart
// Enable debug logging in Ultravox SDK
UltravoxSession.setLogLevel(LogLevel.debug);

// Listen to debug messages
session.on('debug', (message) {
  print('[Ultravox] $message');
});

// View call messages via API
final messages = await ultravoxApi.getCallMessages(callId);
for (final message in messages) {
  print('${message.role}: ${message.text}');
}
```

#### Testing WebRTC Locally
- Use ngrok to expose localhost for webhooks
- Test with emulator/simulator first
- Check audio permissions granted
- Monitor WebRTC connection state

#### Mocking Backend for Development
```dart
// lib/data/datasources/backend_api_mock.dart
class BackendApiMock implements BackendApiClient {
  @override
  Future<void> sendTranscript(String userId, Transcript transcript) async {
    await Future.delayed(Duration(seconds: 2));
    // Simulate webhook after delay
    Timer(Duration(seconds: 5), () {
      _simulateWebhook(userId);
    });
  }

  void _simulateWebhook(String userId) {
    final update = BackendUpdate(
      type: UpdateType.actionPlan,
      title: 'Your action plan is ready',
      message: 'We\'ve created a personalized action plan based on your conversation.',
      data: {...},
    );
    // Trigger webhook handler
    webhookHandler.handleUpdate(update);
  }
}
```

### Current Development Status

**Implemented:**
- ✅ Basic Flutter app structure
- ✅ CLAUDE.md with comprehensive architecture
- ✅ Ultravox API documentation in `docs/`

**To Implement (Priority Order):**
1. **Environment Setup**: `.env` file, `env_config.dart`, API keys
2. **Dependencies**: Add packages to `pubspec.yaml`, run code generation
3. **Data Models**: Ultravox, backend, and user models with Freezed
4. **API Clients**: Ultravox REST API, WebRTC manager, backend API
5. **Use Cases**: Agent configuration, call management, transcript sending
6. **Providers**: Call state, backend updates, auth with Riverpod
7. **UI Screens**: Home, voice call, updates, profile
8. **RAG Setup**: Create corpora via Ultravox web app/API
9. **Backend Server**: Build FastAPI backend (separate repo)
10. **Testing**: Unit tests, integration tests, E2E voice call test

**Reference Documentation:**
- `docs/ultravox-agentscalls.md` - Agents and calls overview
- `docs/ultravox-tools.md` - Tool creation and usage
- `docs/ultravox-customtools.md` - Custom tool implementation
- `docs/ultravox-rag.md` - RAG corpus setup
- `docs/ultravox-webhooks.md` - Webhook integration
- `docs/ultravox-webrtc.md` - WebRTC connection details
- `docs/ultravox-restapi.md` - API endpoints reference

### Code Quality Standards

**Linting:**
- Uses `flutter_lints` package (configured in `analysis_options.yaml`)
- Run `flutter analyze` before committing
- Fix all analyzer warnings

**Formatting:**
- Run `flutter format .` before committing
- Use trailing commas for better diffs

**Testing:**
- Write unit tests for all use cases and repositories
- Widget tests for all screens and complex widgets
- Integration tests for complete voice call flow
- Minimum 70% code coverage

**Code Generation:**
```bash
# After modifying models or providers
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch
```

**Commit Messages:**
- Format: `type(scope): description`
- Types: feat, fix, docs, refactor, test
- Example: `feat(voice): implement stage-based call workflow`
