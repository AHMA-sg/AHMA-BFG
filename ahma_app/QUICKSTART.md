# AHMA Flutter POC - Quick Start Guide

## Prerequisites

1. ✅ Ultravox API key
2. ✅ RAG corpus created ("Caregiver Guides for Seniors")
3. ✅ Flask backend running
4. ✅ Flutter installed

## Setup Steps

### 1. Configure Environment Variables

Edit `/home/aparanjape/ahma/ahma_app/.env`:

```bash
# Ultravox API
ULTRAVOX_API_KEY=your_actual_ultravox_key
ULTRAVOX_BASE_URL=https://api.ultravox.ai/api

# AHMA Backend (Flask)
BACKEND_API_URL=http://localhost:5001
BACKEND_API_KEY=

# Ultravox RAG Corpus ID
CORPUS_ID_CAREGIVER_GUIDES=your_actual_corpus_id
```

**Get your corpus ID:**
```bash
curl https://api.ultravox.ai/api/corpora \
  -H "X-API-Key: YOUR_ULTRAVOX_KEY"
```
Look for "Caregiver Guides for Seniors" and copy its `corpusId`.

### 2. Start Flask Backend

```bash
cd /home/aparanjape/ahma/AHMA-Strands-Agent/backend
source .venv/bin/activate  # or create venv: python -m venv .venv
python app.py
```

Should see: `Running on http://localhost:5001`

### 3. Run Flutter App

```bash
cd /home/aparanjape/ahma/ahma_app
flutter run -d linux  # or -d <your-device>
```

## Usage

1. **Home Screen**: Tap "Start Voice Call"
2. **Voice Call Screen**:
   - Permission prompt for microphone → Allow
   - WebRTC connects to Ultravox
   - Speak with AHMA
   - AHMA follows 3 stages: Assess → Support → Evaluate
   - AHMA can query your caregiver guides corpus
3. **End Call**: Tap red phone button
4. **Backend Processing**: Transcript sent to Flask, router agent processes it

## What Works

✅ WebRTC audio connection with Ultravox
✅ AHMA agent with 3-stage workflow
✅ RAG corpus querying (Caregiver Guides)
✅ Real-time voice conversation
✅ Mute/unmute controls
✅ Transcript capture
✅ Backend integration (transcript → Flask → router agent)

## New Backend Endpoints

Your Flask backend now has:

- `POST /api/ultravox/transcript` - Receives call transcript, processes with router agent
- `POST /api/ultravox/tool-request` - Handles tool requests during live calls
- `POST /api/flutter/webhook/register` - Registers Flutter webhook (for future)

## Troubleshooting

### "Configuration needed" error
- Check `.env` file exists and has valid API keys
- Verify corpus ID is correct

### WebRTC connection fails
- Check microphone permissions granted
- Verify Ultravox API key is valid
- Check network connectivity

### Backend not receiving transcript
- Ensure Flask backend is running on port 5001
- Check BACKEND_API_URL in `.env` is correct
- Look at Flutter console logs for errors

### RAG queries not working
- Verify corpus ID in `.env` matches your corpus
- Ensure corpus has content (documents/web sources)
- Check Ultravox dashboard for corpus status

## Next Steps

### For Production:

1. **Add webhook support**: Backend sends updates back to Flutter
2. **Improve WebRTC signaling**: Handle all WebSocket messages properly
3. **Add user authentication**: Firebase Auth integration
4. **Stage detection**: Automatically detect stage transitions
5. **Real-time transcript**: Display messages as they happen
6. **Error handling**: Better error messages and retry logic
7. **Testing**: Unit tests, integration tests

### Enhance Backend:

1. **Google Calendar integration**: Actually create reminders and blocks
2. **Todoist integration**: Create tasks from conversation
3. **Webhook sender**: Send results back to Flutter
4. **Database**: Store transcripts and actions
5. **Neo4j**: Build caregiver relationship graph

## Testing the Full Flow

1. Start backend: `cd AHMA-Strands-Agent/backend && python app.py`
2. Start Flutter: `cd ahma_app && flutter run`
3. Start voice call
4. Say: "I'm feeling really overwhelmed with caregiving"
5. AHMA should respond empathetically and assess stress
6. Ask: "What support is available for caregivers in Singapore?"
7. AHMA should use queryCorpus to find resources
8. End call
9. Check backend logs for transcript processing
10. Check for router agent actions (calendar, todoist, etc.)

## Logs to Watch

**Flutter console:**
```
[WebRTC] Connecting to...
[Ultravox API] POST /calls
[Call] Started call: call_xyz123
[WebRTC] Remote audio stream received
[Call] Sending transcript to backend
[Backend API] POST /api/ultravox/transcript
```

**Flask console:**
```
📝 [Ultravox] Received transcript for call call_xyz123
✅ [Ultravox] Processed transcript, actions: ...
```

## Files Modified

**Flutter App:**
- `lib/core/config/env_config.dart` - Environment configuration
- `lib/data/datasources/ultravox_api.dart` - Ultravox REST API, tool configuration
- `lib/data/datasources/ultravox_rtc.dart` - WebRTC connection with signaling
- `lib/data/datasources/backend_api.dart` - Flask backend client
- `lib/presentation/providers/call_provider.dart` - Call state, RAG tools
- `lib/presentation/screens/home_screen.dart` - Home UI
- `lib/presentation/screens/voice_call_screen.dart` - Call UI
- `lib/main.dart` - App entry, permissions

**Flask Backend:**
- `backend/ultravox_integration.py` - New Ultravox endpoints (created)
- `backend/app.py` - Registered new routes (modified)

## Support

Check logs in both Flutter console and Flask console for debugging.
All print statements show what's happening at each step.
