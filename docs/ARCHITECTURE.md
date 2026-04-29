# ⚡ Architecture

## Flutter App (Mobile)
- **State Management / UI:** Flutter SDK
- **Location:** `geolocator`
- **Map:** `google_maps_flutter`
- **Push Notifications:** `firebase_messaging`

## Backend (Firebase)
- **Firestore:** Store `users` (live locations) and `alerts` (manual & collision).
- **Firebase Auth:** Anonymous authentication.
- **Firebase Cloud Messaging:** Push notifications for alerts.

## Flow
1. **Live Location:** App sends GPS data to `users` collection every 2-5 seconds.
2. **Alert Trigger:** 
   - *Manual:* User presses "ADA MASALAH DI REL", writes to `alerts` collection.
   - *Collision:* Client calculates distance < 500m & high relative speed. Writes to `alerts`.
3. **Notification:** Client or FCM pushes the alert to nearby users based on location data.
