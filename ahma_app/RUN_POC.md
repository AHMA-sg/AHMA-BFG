# 🚀 Run AHMA POC - Quick Guide

## Prerequisites Check

1. ✅ Ultravox API key
2. ✅ RAG corpus ID ("Caregiver Guides for Seniors")
3. ✅ Flutter dependencies installed
4. ✅ Backend dependencies installed

## Step-by-Step

### 1. Configure .env File

Edit `/home/aparanjape/ahma/ahma_app/.env`:

```bash
ULTRAVOX_API_KEY=your_ultravox_api_key_here
ULTRAVOX_BASE_URL=https://api.ultravox.ai/api
BACKEND_API_URL=http://localhost:5001
BACKEND_API_KEY=
CORPUS_ID_CAREGIVER_GUIDES=your_corpus_id_here
```

**Get Corpus ID:**
```bash
curl https://api.ultravox.ai/api/corpora \
  -H "X-API-Key: YOUR_KEY" | grep "Caregiver Guides"
```

### 2. Start Backend (Terminal 1)

```bash
cd /home/aparanjape/ahma/AHMA-Strands-Agent/backend
./start.sh

# Or manually:
# source .venv/bin/activate
# python3 app.py
```

Wait for: `* Running on http://127.0.0.1:5001`

### 3. Start Flutter App (Terminal 2)

```bash
cd /home/aparanjape/ahma/ahma_app
flutter run -d linux
```

**Alternative - Run on Android Phone:**
1. Enable USB debugging on your Android phone
2. Connect via USB
3. Run: `flutter devices` (should show your phone)
4. Run: `flutter run` (auto-selects phone)

**Note:** Linux desktop is recommended for POC - better audio support than emulators!

## Testing the POC

### Test 1: Voice Call Connection
1. Click "Start Voice Call"
2. Allow microphone permission
3. Wait for "Call in progress" status
4. Speak: "Hello AHMA"
5. Verify you hear AHMA's voice response

### Test 2: Stage-Based Workflow
1. Start call
2. AHMA should greet warmly (Stage 1: Assess)
3. Say: "I'm feeling really overwhelmed with caregiving"
4. Observe stage indicator changes
5. AHMA should provide support (Stage 2: Support)

### Test 3: RAG Corpus Query
1. During call, ask: "What support is available for caregivers in Singapore?"
2. AHMA should use queryCorpus tool
3. Should receive information from your "Caregiver Guides" corpus
4. Watch Flutter console for `[Ultravox API]` logs

### Test 4: Backend Integration
1. Complete a voice call (click end call)
2. Check Flutter console for: `✅ Backend response`
3. Check Backend console for: `📝 [Ultravox] Received transcript`
4. Verify router agent processed the conversation

## Console Logs to Watch

**Flutter Console:**
```
[WebRTC] Connecting to: wss://...
[Ultravox API] POST /calls
[Call] Started call: call_xyz123
[WebRTC] Received remote track: audio
[Call] ✅ Backend response: Transcript processed
[Call] 🎯 Actions taken: ...
```

**Backend Console:**
```
📝 [Ultravox] Received transcript for call call_xyz123
   User: default_user, Stress: elevated
   Messages: 8
✅ [Ultravox] Processed transcript, actions: ...
```

## Troubleshooting

### "Configuration needed" error
- Check `.env` file has all values filled in
- Verify Ultravox API key is correct
- Ensure corpus ID matches your collection

### WebRTC connection fails
```bash
# Check microphone permissions
flutter run -d linux --verbose
# Look for permission errors
```

### Backend not receiving transcript
```bash
# Check backend is running
curl http://localhost:5001/health

# Should return:
# {"status":"healthy","message":"AHMA Backend API is running"}
```

### RAG queries not returning results
- Verify corpus has content (documents or web sources)
- Check corpus ID is correct in `.env`
- View corpus status in Ultravox dashboard

## What Works in POC

✅ Real-time voice conversation with AHMA via Ultravox WebRTC
✅ 3-stage workflow (Assess → Support → Evaluate)
✅ RAG corpus queries for caregiver resources
✅ Mute/unmute audio controls
✅ Call transcript capture
✅ Backend integration (transcript → Flask → router agent)
✅ Stage progress indicators in UI

## Known Limitations

⚠️ Transcript not displayed in real-time (only after call ends)
⚠️ Stage transitions are manual (not auto-detected)
⚠️ Backend webhooks to Flutter not implemented
⚠️ No user authentication (uses default_user)
⚠️ Backend actions (calendar, todoist) are logged but not fully executed

## Next Steps After POC

1. Real-time transcript streaming
2. Auto-detect stage transitions
3. Implement webhooks (backend → Flutter)
4. Add Firebase Auth
5. Complete Google Calendar integration
6. Add action plan UI
7. Todoist task creation from conversation

## Quick Commands Reference

```bash
# Start everything
cd ~/ahma/AHMA-Strands-Agent/backend && ./start.sh &
cd ~/ahma/ahma_app && flutter run -d linux

# Check backend health
curl http://localhost:5001/health

# View backend logs
cd ~/ahma/AHMA-Strands-Agent/backend && tail -f *.log

# Restart backend
pkill -f "python3 app.py"
cd ~/ahma/AHMA-Strands-Agent/backend && ./start.sh
```

## Success Criteria

POC is working if you can:
1. ✅ Start a voice call
2. ✅ Hear AHMA's voice
3. ✅ Have a conversation
4. ✅ Ask about caregiver resources and get answers
5. ✅ See backend receive transcript after call ends

**Ready to test!** 🎉
