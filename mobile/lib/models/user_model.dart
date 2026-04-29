import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final double lat;
  final double lng;
  final double speed;
  final DateTime timestamp;

  UserModel({
    required this.userId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.timestamp,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      userId: id,
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      speed: (data['speed'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
