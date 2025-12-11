import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/vehicle_model.dart';
import 'vehicle_information.dart';
import 'edit_vehicle_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserVehicleScreen extends StatefulWidget {
  const UserVehicleScreen({super.key});

  @override
  State<UserVehicleScreen> createState() => _UserVehicleScreenState();
}

class _UserVehicleScreenState extends State<UserVehicleScreen> {
  bool removeMode = false; // toggle for remove mode

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          'Vehicle Information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildVehicleList(),
        ),
      ),
    );
  }

  Widget _buildVehicleList() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Please sign in'));
    }
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('vehicles')
        .orderBy('vehicle_name')
        .snapshots();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          // No vehicles: don't show the bottom buttons
          return _buildEmptyState();
        }
        final vehicles = docs.map((d) => VehicleModel.fromJson(d.data())).toList();
        return Column(
          children: [
            // Vehicle list
            Expanded(
              child: ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return _VehicleCard(
                    vehicle: vehicle,
                    removeMode: removeMode,
                    onTap: () {
                      if (removeMode) {
                        _removeVehicle(vehicle);
                      } else {
                        _navigateToVehicleDetails(vehicle);
                      }
                    },
                  );
                },
              ),
            ),
            // Action buttons
            const SizedBox(height: 20),
            _buildAddCarButton(),
            const SizedBox(height: 12),
            _buildRemoveCarButton(),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No vehicles registered',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _buildAddCarButton(),
        ],
      ),
    );
  }

  Widget _buildAddCarButton() {
    return SizedBox(
      width: double.infinity,
      height: 70, // Reduced height
      child: ElevatedButton(
        onPressed: _addCar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF29A87A), // Green theme color
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Color(0xFF29A87A), size: 20),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add Vehicle',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveCarButton() {
    return SizedBox(
      width: double.infinity,
      height: 70, // Reduced height to match add button
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            removeMode = !removeMode;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                removeMode ? Icons.close : Icons.remove,
                color: Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              removeMode ? 'Cancel Remove' : 'Remove Vehicle',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VehicleInformationScreen(),
      ),
    );
  }

  Future<void> _removeVehicle(VehicleModel vehicle) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || vehicle.vehicleId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc(vehicle.vehicleId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  void _navigateToVehicleDetails(VehicleModel vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(
          vehicle: vehicle,
        ),
      ),
    ).then((updatedVehicle) {
      if (updatedVehicle != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }
}

class _VehicleCard extends StatefulWidget {
  final VehicleModel vehicle;
  final bool removeMode;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.vehicle,
    required this.removeMode,
    required this.onTap,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  Uint8List? _vehiclePhotoData;
  String? _vehiclePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadVehiclePhoto();
  }

  Future<void> _loadVehiclePhoto() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .doc(widget.vehicle.vehicleId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        
        // Check for Blob photo data first
        if (data['vehicle_photo_data'] != null) {
          final blob = data['vehicle_photo_data'] as Blob;
          setState(() {
            _vehiclePhotoData = blob.bytes;
          });
          return;
        }
        
        // Fallback to URL-based photo
        if (data['vehicle_photo'] != null && data['vehicle_photo'].toString().trim().isNotEmpty) {
          setState(() {
            _vehiclePhotoUrl = data['vehicle_photo'];
          });
          return;
        }
      }
    } catch (e) {
      // Silently handle error - vehicle might not have a photo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Vehicle icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4EEE5),
                    shape: BoxShape.circle,
                  ),
                  child: _VehicleAvatar(
                    photoData: _vehiclePhotoData,
                    photoUrl: _vehiclePhotoUrl,
                  ),
                ),
                const SizedBox(width: 16),
                // Vehicle details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle name and nickname
                      Text(
                        widget.vehicle.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Plate number
                      Text(
                        widget.vehicle.vehiclePlateNum,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Mileage
                      Text(
                        'Mileage: ${widget.vehicle.mileageDisplay}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Vehicle type
                      Text(
                        '${widget.vehicle.vehicleType} (Petrol / Diesel)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  widget.removeMode ? Icons.delete : Icons.chevron_right,
                  color: widget.removeMode ? Colors.red : Colors.black87,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleAvatar extends StatelessWidget {
  final Uint8List? photoData;
  final String? photoUrl;
  
  const _VehicleAvatar({
    this.photoData,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Priority: Blob data first, then URL, then default icon
    if (photoData != null) {
      return ClipOval(
        child: Image.memory(
          photoData!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.directions_car, color: Colors.black87, size: 24);
          },
        ),
      );
    }
    
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.directions_car, color: Colors.black87, size: 24);
          },
        ),
      );
    }
    
    // Default car icon
    return const Icon(Icons.directions_car, color: Colors.black87, size: 24);
  }
}
