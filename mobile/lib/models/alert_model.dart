import 'package:cloud_firestore/cloud_firestore.dart';

class AlertModel {
  final String alertId;
  final String type; // "collision" | "manual"
  final double lat;
  final double lng;
  final DateTime createdAt;

  AlertModel({
    required this.alertId,
    required this.type,
    required this.lat,
    required this.lng,
    required this.createdAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> data, String id) {
    return AlertModel(
      alertId: id,
      type: data['type'] ?? 'unknown',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alert_id': alertId,
      'type': type,
      'lat': lat,
      'lng': lng,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
