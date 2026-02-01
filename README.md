# 💖 Amorae - AI Companion App

A personalized AI companion application built with Flutter and FastAPI, featuring emotional intelligence, memory persistence, and customizable personality traits.

## ✨ Features

### 🤖 AI Companion
- **Multiple Personas**: 13+ unique AI personalities including Luna (Girlfriend), Albert Einstein (Genius Scientist), Jack Dawson (Artist), and more
- **Personalized Conversations**: Powered by OpenAI's GPT-4o-mini with context-aware responses
- **Emotional Intelligence**: Each persona has unique traits, speaking styles, and emotional responses
- **Memory System**: Long-term conversation memory with fact extraction and recall
- **Thread-Specific Personas**: Each chat maintains its own persona for consistent conversations

### 💬 Chat Experience
- **Persona Selection**: Choose from 13+ AI companions with unique personalities
- **Real-time Messaging**: Smooth, responsive chat interface with typing indicators
- **Thread Management**: Organize conversations with different personas in separate threads
- **Message History**: Persistent message storage with Firebase Firestore
- **Smart Navigation**: Seamless navigation with Android back gesture support

### ⚙️ Customization
- **AI Personas**: 13+ unique personalities including:
  - 💕 Luna - Your caring girlfriend companion
  - 🧪 Albert Einstein - Genius scientist and philosopher
  - 🎨 Jack Dawson - Free-spirited artist
  - 🐉 Khaleesi - Dragon queen leader
  - 🎯 Many more specialized personas
- **Companion Styles**: Warm & Supportive, Playful, Calm, or Direct
- **Preferences**: Pet names, flirting, and interaction style controls
- **Profile Management**: Edit display name and companion settings
- **Plan Tiers**: Free and Pro subscription options

### 🔐 Security & Privacy
- **Google Sign-In**: Secure OAuth 2.0 authentication
- **Firebase Auth**: Industry-standard user management
- **Data Encryption**: Secure data transmission and storage
- **Privacy Controls**: User data management and privacy settings

## 🏗️ Architecture

### Frontend (Flutter)
```
lib/
├── app/                    # App configuration & routing
│   ├── router.dart        # Go Router navigation
│   └── theme/             # Design system
├── features/              # Feature modules
│   ├── auth/              # Authentication
│   ├── chat/              # Messaging
│   ├── onboarding/        # User onboarding
│   └── settings/          # User preferences
└── shared/                # Shared utilities
    ├── models/            # Data models
    ├── providers/         # Riverpod state management
    ├── services/          # API & Firebase services
    └── widgets/           # Reusable UI components
```

### Backend (FastAPI)
```
backend/
├── app/
│   ├── api/               # API endpoints
│   │   ├── chat.py       # Chat endpoints
│   │   ├── memory.py     # Memory management
│   │   └── privacy.py    # Privacy controls
│   ├── core/              # Core configuration
│   │   ├── config.py     # Settings
│   │   ├── auth.py       # Firebase Auth
│   │   └── firebase.py   # Firestore client
│   ├── models/            # Pydantic schemas
│   └── services/          # Business logic
│       ├── chat_service.py      # Chat logic with persona support
│       ├── llm_service.py       # OpenAI integration
│       ├── memory_service.py    # Memory management
│       └── persona_prompts.py   # 13+ AI persona definitions
└── pyproject.toml         # Dependencies
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.9.0 or higher
- **Python**: 3.11 or higher
- **Firebase Project**: With Authentication and Firestore enabled
- **OpenAI API Key**: For GPT-4o-mini access

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   # or using pip install -e .
   ```

3. **Configure environment variables** - Create `.env` file:
   ```env
   # OpenAI
   OPENAI_API_KEY=your_openai_api_key_here
   
   # Firebase
   FIREBASE_CREDENTIALS_PATH=path/to/firebase-adminsdk.json
   FIREBASE_DATABASE_ID=amorae
   
   # Server
   BACKEND_HOST=0.0.0.0
   BACKEND_PORT=8000
   ```

4. **Add Firebase Admin SDK credentials**:
   - Download service account key from Firebase Console
   - Place JSON file in `backend/` directory
   - Update `FIREBASE_CREDENTIALS_PATH` in `.env`

5. **Run backend server**:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

   Server will be available at `http://localhost:8000`
   API docs at `http://localhost:8000/docs`

### Frontend Setup

1. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure Firebase**:
   
   **Android**:
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`
   - Add SHA-1 and SHA-256 certificates to Firebase project:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
     ```

   **iOS**:
   - Download `GoogleService-Info.plist` from Firebase Console
   - Place in `ios/Runner/`

3. **Update API endpoint** in `lib/shared/services/api_client.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000';
   ```
   
   For physical devices, use your computer's local IP (e.g., `http://192.168.0.147:8000`)

4. **Enable Google Sign-In**:
   - Add OAuth 2.0 Client IDs in Google Cloud Console
   - Configure consent screen
   - Add authorized domains

5. **Run the app**:
   ```bash
   flutter run
   ```

## 🎭 AI Personas

Amorae features 13+ unique AI personalities, each with distinct traits, speaking styles, and emotional characteristics:

### Available Personas

| Persona | Type | Description |
|---------|------|-------------|
| 💕 **Luna** | Girlfriend | Caring, supportive, emotionally intelligent |
| 🧪 **Albert Einstein** | Genius Scientist | Philosophical, curious, intellectually deep |
| 🎨 **Jack Dawson** | Free-Spirited Artist | Adventurous, romantic, creative |
| 🐉 **Khaleesi** | Dragon Queen | Strong, determined, regal leader |
| 🧠 **Sherlock** | Master Detective | Analytical, observant, logical |
| 🪄 **Gandalf** | Wise Wizard | Patient, wise, mystical guidance |
| 😂 **Chandler** | Sarcastic Friend | Humorous, loyal, witty |
| 🏀 **Michael Jordan** | Champion | Competitive, motivational, disciplined |
| 🌟 **Tony Stark** | Genius Billionaire | Confident, innovative, charismatic |
| 🎵 **Freddie Mercury** | Rock Legend | Flamboyant, passionate, inspiring |
| 🌊 **Moana** | Wayfinder | Brave, adventurous, connected to nature |
| 🦁 **Simba** | Lion King | Noble, courageous, responsible leader |
| 🧘 **Buddha** | Enlightened Master | Peaceful, compassionate, philosophical |

Each persona maintains:
- **Unique Voice**: Distinct speaking patterns and vocabulary
- **Consistent Personality**: Maintains character traits across conversations
- **Thread Persistence**: Each chat thread remembers its persona
- **Contextual Memory**: Recalls facts and previous interactions

## 🔧 Configuration

### Firebase Firestore Structure

**Users Collection** (`users/{userId}`):
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "photoUrl": "string",
  "plan": {
    "tier": "free|pro",
    "messageLimit": 100,
    "messagesUsed": 0
  },
  "prefs": {
    "selectedPersona": "luna",
    "relationshipMode": "romantic|friendly",
    "companionStyle": "warm_supportive|playful|calm|direct",
    "emojiLevel": "none|minimal|moderate|expressive",
    "petNamesAllowed": true,
    "flirtingAllowed": true
  },
  "createdAt": "timestamp",
  "lastActive": "timestamp"
}
```

**Threads Collection** (`threads/{threadId}`):
```json
{
  "id": "string",
  "userId": "string",
  "title": "string",
  "persona": "luna|einstein|jack|khaleesi|...",
  "lastMessage": "string",
  "lastMessageAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Messages Collection** (`messages/{messageId}`):
```json
{
  "id": "string",
  "threadId": "string",
  "seq": "number",
  "role": "user|assistant",
  "content": "string",
  "attachments": [],
  "createdAt": "timestamp"
}
```

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /threads/{threadId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    match /memories/{memoryId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### Firestore Indexes

Create composite index for messages:
- Collection: `messages`
- Fields: `threadId` (Ascending), `seq` (Ascending)

## 🔑 API Endpoints

### Chat
- `POST /v1/chat/send` - Send message and get AI response (supports persona parameter)
- `GET /v1/chat/threads/{thread_id}/messages` - Get thread messages

### Memory
- `POST /v1/memory/extract` - Extract facts from conversation
- `GET /v1/memory/recall` - Retrieve relevant memories
- `GET /v1/memory/user/{user_id}` - Get all user memories

### Privacy
- `DELETE /v1/privacy/user/{user_id}/threads` - Delete all threads
- `DELETE /v1/privacy/user/{user_id}/memories` - Delete all memories
- `DELETE /v1/privacy/user/{user_id}` - Delete user account

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.9.0+
- **State Management**: Riverpod 2.6.1
- **Navigation**: Go Router 14.8.1
- **HTTP Client**: Dio 5.7.0
- **Authentication**: Firebase Auth 5.3.3
- **Database**: Cloud Firestore 5.5.2
- **Animations**: Flutter Animate 4.5.0

### Backend
- **Framework**: FastAPI 0.115.12
- **LLM**: OpenAI API 2.16.0 (GPT-4o-mini, GPT-4o)
- **Database**: Firebase Admin SDK 6.6.0
- **HTTP Client**: httpx 0.28.1
- **Environment**: Python 3.11+

## 📱 Supported Platforms

- ✅ Android (with native back gesture support)
- ✅ iOS
- 🚧 Web (planned)

## 📋 Recent Updates

### Version 1.1 (February 2026)
- ✅ **13+ AI Personas**: Multiple unique personalities to chat with
- ✅ **Thread-Specific Personas**: Each chat maintains its own persona
- ✅ **Smart Persona Drawer**: Select persona to open/create chat automatically
- ✅ **Fixed Navigation**: Proper Android back gesture handling (Chat/Settings → Home → App Close)
- ✅ **Fixed Message Duplication**: Removed optimistic message creation
- ✅ **Fixed Deletion Errors**: Smooth thread deletion without permission errors
- ✅ **Backend Persona Override**: Threads use their own persona instead of user default
- ✅ **UI Improvements**: Removed unnecessary FAB buttons, cleaner interface

## 🤝 Contributing

This is a private project. If you're part of the team and want to contribute, please follow these steps:

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request for review

## 📄 License

Copyright © 2026 Ilham Labs AI. All rights reserved.

This is proprietary software. Unauthorized copying, distribution, modification, or use of this software is strictly prohibited.

## 🙏 Acknowledgments

- OpenAI for GPT-4o-mini and GPT-4o models
- Firebase for authentication and database infrastructure
- Flutter team for the excellent framework
- FastAPI for the modern Python web framework

## 📞 Support

For issues or questions:
- Contact: support@ilhamlabs.ai

---

**Made with 💖 by Ilham Labs AI**

*Copyright © 2026 Ilham Labs AI. All rights reserved.*
