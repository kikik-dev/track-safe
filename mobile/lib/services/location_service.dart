import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/user_model.dart';

class LocationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionStream;
  WebSocketChannel? _channel;

  // IMPORTANT: For Android emulator, use 10.0.2.2 instead of localhost
  // For physical devices or iOS simulator, use your computer's local IP (e.g. 192.168.1.x)
  final String _wsUrl = 'ws://10.0.2.2:8080';

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    } 

    return true;
  }

  void startTracking() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Connect to WebSocket Server (v1.1)
    _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          _sendLocationViaWebSocket(uid, position);
        }
      }
    );
  }

  Stream<dynamic>? get wsStream => _channel?.stream;

  void stopTracking() {
    _positionStream?.cancel();
    _channel?.sink.close();
  }

  void _sendLocationViaWebSocket(String uid, Position position) {
    if (_channel == null) return;

    final payload = {
      'type': 'location_update',
      'payload': {
        'userId': uid,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
      }
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  // Phase 4 Utility: Calculate distance
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
