import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/alert_model.dart';
import '../models/user_model.dart';
import 'location_service.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initFCM() async {
    NotificationSettings settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      print('FCM Token: $token');
      // Subscribe to general topic for broadcasts
      await _fcm.subscribeToTopic('rail_alerts');
    }
  }

  Future<void> triggerAlert({
    required String type,
    required double lat,
    required double lng,
  }) async {
    try {
      final alertRef = _firestore.collection('alerts').doc();
      final alertModel = AlertModel(
        alertId: alertRef.id,
        type: type, // "collision" or "manual"
        lat: lat,
        lng: lng,
        createdAt: DateTime.now(),
      );

      await alertRef.set(alertModel.toMap());
    } catch (e) {
      print('Error triggering alert: $e');
    }
  }

  Stream<List<AlertModel>> listenToAlerts() {
    // Listen for recent alerts
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _firestore
        .collection('alerts')
        .where('created_at', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AlertModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Phase 4 Utility: Calculate Relative Speed
  static double calculateRelativeSpeed(double mySpeed, double otherSpeed) {
    // Simplified: Just additive for worst-case head-on collision
    return mySpeed + otherSpeed; 
  }

  void checkCollision(UserModel me, List<UserModel> nearbyUsers, Function(AlertModel) onCollision) {
    const double DISTANCE_THRESHOLD = 500; // meters
    const double SPEED_THRESHOLD = 5.0; // m/s relative speed roughly 18km/h

    for (var user in nearbyUsers) {
      if (user.userId == me.userId) continue;

      double distance = LocationService.calculateDistance(
        me.lat, me.lng, user.lat, user.lng,
      );
      double relativeSpeed = calculateRelativeSpeed(me.speed, user.speed);

      if (distance < DISTANCE_THRESHOLD && relativeSpeed > SPEED_THRESHOLD) {
        // Condition met
        final alert = AlertModel(
          alertId: "local_collision_${user.userId}",
          type: "collision",
          lat: me.lat,
          lng: me.lng,
          createdAt: DateTime.now(),
        );
        onCollision(alert);
        break; // Trigger once per tick
      }
    }
  }
}
