# 🚆 TrackSafe – Railway Alert (Lite Version)
> **Open Source PRD · MVP Edition**

---

## 🎯 Goal

Aplikasi mobile sederhana berbasis Flutter untuk:

- Share posisi kereta/user secara **realtime**
- Kirim **alert otomatis** saat terdeteksi potensi tabrakan atau berhenti mendadak

---

## 👥 Target Pengguna (Realistis)

| Segmen | Keterangan |
|--------|-----------|
| 🚂 Railfans & Volunteer | Komunitas pecinta kereta api |
| 🎓 Edukasi | Demo sistem keselamatan sederhana |
| 🧪 Proof of Concept | Prototipe safety awareness |

---

## 🚨 Core Features (MVP)

### 1. Live Location Sharing
- Kirim data GPS setiap **2–5 detik**
- Tampil pada peta secara real-time

### 2. Simple Collision Detection

Logika deteksi berbasis klien:

```
IF jarak antar user < X meter
AND kecepatan saling mendekat > threshold
→ TRIGGER ALERT
```

### 3. Emergency Alert Button
- Tombol manual: **"ADA MASALAH DI REL"**
- Broadcast ke semua user di sekitar lokasi

### 4. Push Notification
- Alert real-time dikirim ke device pengguna lain via FCM

---

## 🧱 Tech Stack (100% Gratis)

### 📱 Mobile App

| Komponen | Detail |
|----------|--------|
| Framework | Flutter |
| Lokasi | `geolocator` |
| Peta | `google_maps_flutter` |
| Notifikasi | `firebase_messaging` |

### ☁️ Backend (No Server Maintenance)

**Firebase** dipilih karena:
- ✅ Free tier mencukupi untuk MVP
- ✅ Realtime built-in
- ✅ Push notification mudah diintegrasikan
- ✅ Tidak perlu VPS / backend custom / MQTT server

### 🔥 Firebase Services

| Service | Fungsi |
|---------|--------|
| **Firestore** | Simpan & query posisi user |
| **Realtime DB** | *(opsional)* Update lebih cepat |
| **Cloud Messaging (FCM)** | Push notification |
| **Auth (Anonymous)** | Login tanpa registrasi |

---

## ⚡ Arsitektur

```
Flutter App
    │
    ▼
Firebase (Firestore)
    │
    ▼
Other Devices
```

> Sederhana, tidak ada lapisan server tambahan.

---

## 📡 Data Model

### Collection: `users`

```json
{
  "user_id": "string",
  "lat": "number",
  "lng": "number",
  "speed": "number",
  "timestamp": "timestamp"
}
```

### Collection: `alerts`

```json
{
  "alert_id": "string",
  "type": "collision | manual",
  "lat": "number",
  "lng": "number",
  "created_at": "timestamp"
}
```

---

## 🧠 Logic Detection (Client-Side)

Di dalam Flutter app:

```dart
// Pseudocode
for (user in nearbyUsers) {
  double distance = calculateDistance(myLocation, user.location);
  double relativeSpeed = calculateRelativeSpeed(mySpeed, user.speed, bearing);

  if (distance < 500 && relativeSpeed > THRESHOLD) {
    triggerAlert(AlertType.collision);
  }
}
```

---

## 🔔 Notifikasi

Flow menggunakan **Firebase Cloud Messaging**:

```
Alert dibuat (auto/manual)
    │
    ▼
Firestore menulis ke collection alerts
    │
    ▼
FCM broadcast ke semua user nearby
    │
    ▼
Device lain menerima push notification
```

---

## 📂 Struktur Repo

```
railway-alert/
├── mobile/                  # Flutter app
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
├── firebase/
│   ├── rules.firestore      # Security rules
│   └── indexes.json         # Query indexes
├── docs/
│   ├── PRD.md
│   └── ARCHITECTURE.md
└── README.md
```

---

## 📖 README (Konten Penting)

1. **Tujuan project** – safety awareness & edukasi
2. **Disclaimer** – ⚠️ Bukan sistem resmi, tidak untuk operasi kereta sungguhan
3. **Cara menjalankan:**

```bash
# 1. Setup Firebase project & download google-services.json
# 2. Jalankan aplikasi
flutter pub get
flutter run

# 3. Build APK
flutter build apk
```

---

## 🔐 Security (Minimal tapi Penting)

- Batasi read/write menggunakan **Firebase Security Rules**
- Gunakan **radius query** agar tidak mengambil semua user global

Contoh Firestore Rule:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /alerts/{alertId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🚀 Deployment

```bash
# Build release APK
flutter build apk --release
```

Distribusi via:
- **GitHub Releases** – paling mudah untuk komunitas
- **F-Droid** – jika ingin full open source tanpa Play Store

---

## 💡 Upgrade Path

Setelah MVP stabil, roadmap pengembangan lanjutan:

| Fase | Fitur |
|------|-------|
| v1.1 | WebSocket server (latensi lebih rendah) |
| v1.2 | AI detection berbasis kamera rel |
| v2.0 | Integrasi sensor IoT |
| v2.x | Offline fallback via SMS |

---

## ⚠️ Reality Check

| | Status |
|--|--------|
| Sistem kereta real / operasional | ❌ Belum memenuhi standar |
| Edukasi & demo safety system | ✅ Sangat cocok |
| Portfolio & open source contribution | ✅ Sangat cocok |
| Proof of concept teknologi | ✅ Sangat cocok |

---

## 🧩 Nama Project

> **TrackSafe** – *Track people. Stay safe.*

---

*PRD ini dibuat sebagai panduan pengembangan open source. Kontribusi sangat welcome!*
