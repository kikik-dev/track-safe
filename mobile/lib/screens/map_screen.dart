import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';
import '../services/alert_service.dart';
import '../models/user_model.dart';
import '../models/alert_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final AlertService _alertService = AlertService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  Map<String, Marker> _markers = {};
  bool _isTracking = false;
  
  UserModel? _myLastModel;
  AlertModel? _activeAlert;
  StreamSubscription? _usersSub;
  StreamSubscription? _alertsSub;

  @override
  void initState() {
    super.initState();
    _alertService.initFCM();
    _initLocation();
    _listenToGlobalAlerts();
  }

  Future<void> _initLocation() async {
    bool hasPermission = await _locationService.requestPermission();
    if (hasPermission) {
      _toggleTracking(true);
      _listenToUsers();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
    }
  }

  void _toggleTracking(bool enable) {
    setState(() {
      _isTracking = enable;
    });
    if (enable) {
      _locationService.startTracking();
    } else {
      _locationService.stopTracking();
    }
  }

  void _listenToUsers() {
    _usersSub = _firestore.collection('users').snapshots().listen((snapshot) {
      final currentUid = _auth.currentUser?.uid;
      Map<String, Marker> updatedMarkers = {};
      List<UserModel> allUsers = [];

      for (var doc in snapshot.docs) {
        final userModel = UserModel.fromMap(doc.data(), doc.id);
        allUsers.add(userModel);
        final isMe = userModel.userId == currentUid;

        if (isMe) {
          _myLastModel = userModel;
        }

        updatedMarkers[userModel.userId] = Marker(
          markerId: MarkerId(userModel.userId),
          position: LatLng(userModel.lat, userModel.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isMe ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: isMe ? "My Location" : "User: ${userModel.userId.substring(0, 5)}",
            snippet: "Speed: ${userModel.speed.toStringAsFixed(2)} m/s",
          ),
        );
      }

      setState(() {
        _markers = updatedMarkers;
      });

      // Run collision detection
      if (_myLastModel != null && _isTracking) {
        _alertService.checkCollision(_myLastModel!, allUsers, (alert) {
          // Trigger global alert via Firestore if not already active
          if (_activeAlert == null) {
            _alertService.triggerAlert(
              type: alert.type, 
              lat: alert.lat, 
              lng: alert.lng,
            );
          }
        });
      }
    });
  }

  void _listenToGlobalAlerts() {
    _alertsSub = _alertService.listenToAlerts().listen((alerts) {
      if (alerts.isNotEmpty) {
        // Show most recent alert within the last 5 minutes
        final recent = alerts.first;
        if (DateTime.now().difference(recent.createdAt).inMinutes < 5) {
          setState(() {
            _activeAlert = recent;
          });
          _showAlertDialog(recent);
        } else {
          setState(() {
            _activeAlert = null;
          });
        }
      }
    });
  }

  void _showAlertDialog(AlertModel alert) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 EMERGENCY ALERT 🚨', style: TextStyle(color: Colors.red)),
        content: Text(
          alert.type == 'collision' 
          ? 'Potensi Tabrakan / Jarak Terlalu Dekat Terdeteksi!' 
          : 'Ada Laporan Masalah di Rel Sekitar Anda!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activeAlert = null;
              });
            },
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _usersSub?.cancel();
    _alertsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackSafe'),
        backgroundColor: Colors.redAccent,
        actions: [
          Row(
            children: [
              const Text("Tracking"),
              Switch(
                value: _isTracking,
                onChanged: _toggleTracking,
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-6.200000, 106.816666),
              zoom: 12,
            ),
            markers: _markers.values.toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          // Phase 7: UI Polish - Visual Flashing for Alerts
          if (_activeAlert != null)
            IgnorePointer(
              child: Container(
                color: Colors.red.withOpacity(0.4),
              ),
            ),
            
          if (!_isTracking)
            const Center(
              child: Card(
                color: Colors.white70,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Tracking disabled for privacy.', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          // Phase 5: Emergency Button
          Positioned(
            bottom: 32,
            left: 32,
            right: 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                )
              ),
              icon: const Icon(Icons.warning_amber_rounded, size: 28),
              label: const Text(
                'ADA MASALAH DI REL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (_myLastModel != null) {
                  _alertService.triggerAlert(
                    type: 'manual', 
                    lat: _myLastModel!.lat, 
                    lng: _myLastModel!.lng,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokasi belum ditemukan')),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (_myLastModel != null) {
                  _alertService.triggerAlert(
                    type: 'manual', 
                    lat: _myLastModel!.lat, 
                    lng: _myLastModel!.lng,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lokasi belum ditemukan')),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
