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

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
          SnackBar(
            content: const Text('Location permission required'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: Colors.redAccent, size: 32),
            SizedBox(width: 10),
            Expanded(child: Text('EMERGENCY', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.type == 'collision' 
              ? 'Potensi tabrakan atau jarak terlalu dekat terdeteksi di area ini!' 
              : 'Ada laporan masalah di rel sekitar Anda. Harap berhati-hati!',
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan periksa kecepatan dan jaga jarak aman.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activeAlert = null;
              });
            },
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationService.stopTracking();
    _usersSub?.cancel();
    _alertsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'TrackSafe',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
            myLocationButtonEnabled: false, // We'll use a custom button or just let map handle it
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          // Alert Red Flash overlay
          if (_activeAlert != null)
            IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                color: Colors.redAccent.withOpacity(0.3),
              ),
            ),
            
          // Tracking Disabled Overlay
          if (!_isTracking)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.location_off_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Pelacakan Nonaktif',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aktifkan pelacakan untuk membagikan\nlokasi dan menerima peringatan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Custom Floating UI Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Top Right Controls (Status Toggle)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                          child: Text(
                            _isTracking ? "LIVE" : "OFFLINE",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isTracking ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isTracking,
                          onChanged: _toggleTracking,
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Bottom Controls
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Re-center Map Button
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        onPressed: () async {
                          if (_myLastModel != null && _mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(_myLastModel!.lat, _myLastModel!.lng),
                                15,
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.my_location_rounded),
                      ),
                      const SizedBox(height: 16),
                      // Emergency Button
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 8,
                              shadowColor: Colors.redAccent.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.warning_amber_rounded, size: 28),
                            label: const Text(
                              'ADA MASALAH DI REL',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
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
                                  SnackBar(
                                    content: const Text('Lokasi belum ditemukan'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
