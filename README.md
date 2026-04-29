# 🚆 TrackSafe – Railway Alert

> **Open Source · Proof of Concept · Safety Awareness**

TrackSafe is a lightweight, mobile application built with **Flutter** designed to provide real-time location sharing and automatic safety alerts for railway enthusiasts, volunteers, and educational demonstrations. 

**⚠️ DISCLAIMER:** *This is a Proof of Concept (PoC) and educational tool. It is NOT an official railway safety system and MUST NOT be used for real train operations.*

---

## ✨ Key Features

* **📡 Live Location Tracking:** Broadcasts user/device GPS locations in real-time.
* **⚡ Low-Latency Updates (v1.1):** Utilizes a Node.js WebSocket server for high-frequency, low-latency location streaming, falling back to Firebase when necessary.
* **💥 Collision Detection (Client-Side):** Automatically calculates distance and relative speed between nearby users to trigger warnings if a potential collision or dangerous proximity is detected.
* **🚨 Emergency Alert Button:** A manual trigger ("ADA MASALAH DI REL") to instantly broadcast hazard warnings to all nearby users.
* **🔔 Push Notifications:** Integrates with Firebase Cloud Messaging (FCM) to deliver critical alerts directly to the device, even when the app is in the background.
* **🎨 Modern UI/UX:** A sleek, responsive map interface with pulsating alert buttons, visual red-screen flash warnings, and smooth animations.

---

## 🧱 Tech Stack

This project is built using 100% free/open-source tier technologies:

### Mobile Application
* **Framework:** Flutter (Dart)
* **Maps:** `google_maps_flutter`
* **Location:** `geolocator`
* **WebSockets:** `web_socket_channel`

### Backend Services
* **Real-time Engine:** Node.js WebSocket Server (`ws`) for location telemetry.
* **Database & Auth:** Firebase Firestore (Alerts & Fallback tracking) & Firebase Anonymous Auth.
* **Notifications:** Firebase Cloud Messaging (FCM).

---

## 📂 Project Structure

```text
track-safe/
├── mobile/                  # The Flutter Mobile Application
│   ├── lib/                 # Dart source code (UI, Models, Services)
│   └── pubspec.yaml         # Flutter dependencies
├── websocket_server/        # Node.js WebSocket Server (v1.1)
│   ├── index.js             # Server logic
│   └── package.json         # Node dependencies
├── firebase/                # Firebase configuration rules
│   ├── rules.firestore      # Firestore Security Rules
│   └── indexes.json         # Firestore Query Indexes
└── docs/                    # Additional architectural documentation
```

---

## 🚀 Getting Started

Follow these steps to get the project running locally.

### 1. Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (v3.5.0 or higher recommended).
* [Node.js](https://nodejs.org/) installed (for the WebSocket server).
* A [Firebase Project](https://console.firebase.google.com/) with Firestore, Anonymous Auth, and Cloud Messaging enabled.

### 2. Firebase Configuration
1. Create an app (Android/iOS) in your Firebase Console.
2. Download the `google-services.json` (for Android) and place it inside `mobile/android/app/`.
3. (Optional) Download `GoogleService-Info.plist` (for iOS) and place it inside `mobile/ios/Runner/`.
4. Deploy the Firestore security rules provided in the `firebase/rules.firestore` file.

### 3. Running the WebSocket Server (Backend)
The WebSocket server handles the high-frequency location data.

```bash
cd websocket_server
npm install
npm start
```
*The server will start on `ws://localhost:8080`. Note: If testing on an Android Emulator, the app uses `ws://10.0.2.2:8080` by default to reach your host machine.*

### 4. Running the Flutter App (Frontend)

Open a new terminal window:

```bash
cd mobile

# Fetch dependencies
flutter pub get

# Run the app on a connected device or emulator
flutter run
```

---

## ⚙️ How Collision Detection Works

The logic operates entirely on the client side to reduce server load. Every time a location update is received:
1. The app iterates through all nearby users.
2. It calculates the geographic distance (`geolocator`) and relative speed.
3. If `distance < THRESHOLD` and `speed` indicates convergence, a `collision` alert is generated.
4. The alert is written to Firestore, which triggers FCM push notifications to other users in the vicinity.

---

## 💡 Roadmap & Upgrades

* **v1.1 (Current):** Implemented WebSocket server for lower latency.
* **v1.2 (Planned):** AI detection based on track cameras.
* **v2.0 (Planned):** IoT sensor integration on level crossings.

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request or open an issue. Ensure that any new features are thoroughly tested and documented.

---

*TrackSafe – Track people. Stay safe.*
