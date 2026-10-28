# TELOS — Production Mobile Application & Backend Platform

TELOS is an advanced, production-oriented personal productivity, track-based planning, collaborative work, social interaction, and AI-powered goal management application designed for Android and iOS.

---

## 🏗️ Architecture Overview

The system is organized into two primary components:

```
Telos/
├── FEATURE_CHECKLIST.md         # Full feature checklist with status tracking
├── backend/                    # Node.js + Express + MongoDB + Socket.IO + AI API
│   ├── package.json
│   ├── server.js               # Express HTTP + Socket.IO server setup
│   ├── .env.example
│   └── src/
│       ├── config/             # Database connection & configurations
│       ├── controllers/        # Business logic for all modules
│       ├── middleware/         # JWT Auth & Security middleware
│       ├── models/             # Mongoose schemas (User, Task, Track, Message, etc.)
│       ├── routes/             # RESTful API endpoints
│       └── sockets/            # Real-time WebSocket & WebRTC calling handler
│
└── telos_mobile/               # Flutter & Dart Clean Architecture Mobile App
    ├── pubspec.yaml
    ├── android/                # Android native project, Gradle & Manifest
    └── lib/
        ├── main.dart           # App entry, Providers setup, Theme & Routing
        ├── core/
        │   ├── constants/      # App constants & network URLs
        │   ├── theme/          # Custom Material 3 Dark/Light themes
        │   ├── storage/        # SharedPreferences persistence
        │   ├── network/        # HTTP API client & Socket.IO client
        │   ├── models/         # Dart data models
        │   └── providers/      # State management (Tasks, Tracks, Auth, AI, etc.)
        └── features/
            ├── auth/           # Welcome & Google Sign-In & Onboarding
            ├── navigation/     # Persistent Top & 5-Destination Bottom Navigation
            ├── home/           # Today's Tasks, More to Know Details & Analytics
            ├── tracks/         # Your Tracks, More Options, Public Tracks, Templates
            ├── add/            # Creation Hub, Create Task, Create Track, Flowchart
            ├── messages/       # 1-on-1, Group Chat, Admin Tasks, Audio/Video Calls
            ├── profile/        # User Profile, Public/Private Tracks, Posts Feed
            ├── search/         # Global Multi-Entity & Interface Command Search
            ├── ai_planner/     # AI Assistant, Personal QA, Plan Preview & Approve
            ├── rewards/        # Points Chest, Streak Flame, Achievements Ledger
            └── settings/       # Theme, Granular Notifications, Language, Logout
```

---

## 🚀 How to Run the TELOS Backend

### Prerequisites
- Node.js (v18+ or v24+ recommended)
- MongoDB running locally at `127.0.0.1:27017` or a MongoDB Atlas URI

### 1. Install Dependencies & Start Server
```powershell
cd c:\Users\venil\Desktop\Telos\backend
npm install
npm run start
```
The server will start on port `5000`:
- **Local API Health Check:** `http://localhost:5000/api/health`
- **Network API:** `http://0.0.0.0:5000/api/health`

---

## 📱 How to Run TELOS on a Physical Android Phone

### 1. Prerequisites
- **Flutter SDK:** Ensure Flutter SDK is installed and added to your system `PATH`.
- **Android Studio / Android SDK:** Android SDK platform 34 and build-tools installed.
- **Java JDK:** JDK 17 or higher.

### 2. Connect Your Android Device
1. On your Android phone, enable **Developer Options**:
   - Go to `Settings` → `About phone` → tap `Build number` 7 times.
2. Inside `Settings` → `System` → `Developer options`:
   - Turn on **USB Debugging**.
3. Plug the phone into your computer via a USB cable.
4. Verify your device is recognized by running:
```powershell
adb devices
```
*(Your phone will appear with a device identifier and status `device`)*

### 3. Run the Flutter Mobile Application
```powershell
cd c:\Users\venil\Desktop\Telos\telos_mobile
flutter pub get
flutter run
```

---

## 🔑 Google OAuth & Firebase Cloud Messaging Setup

### 1. Google OAuth Client Configuration
1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Create or select a project (e.g. `Telos App`).
3. Under **APIs & Services** → **Credentials**:
   - Create an **OAuth 2.0 Web Client ID**: Put this ID into `backend/.env` under `GOOGLE_CLIENT_ID`.
   - Create an **Android OAuth Client ID**: Set package name to `com.telos.app` and add your debug SHA-1 signing fingerprint:
     ```powershell
     keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```

### 2. Firebase Cloud Messaging (Push Notifications)
1. In [Firebase Console](https://console.firebase.google.com/), create a project `Telos`.
2. Add an Android App with package name `com.telos.app`.
3. Download `google-services.json` and place it in:
   `telos_mobile/android/app/google-services.json`
