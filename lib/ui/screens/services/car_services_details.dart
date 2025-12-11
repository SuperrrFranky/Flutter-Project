import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/bottom_navbar.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';
import '../booking/booking.dart';
import '../../../models/vehicle_model.dart';

class CarServicesDetailsScreen extends StatefulWidget {
  final BookingModel booking;
  
  const CarServicesDetailsScreen({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<CarServicesDetailsScreen> createState() => _CarServicesDetailsScreenState();
}

class _CarServicesDetailsScreenState extends State<CarServicesDetailsScreen> {
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

      // Get vehicles from user's collection
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vehicles')
          .get();

      if (vehiclesSnapshot.docs.isEmpty) return;

      // Try to match vehicle by booking vehicle name or type
      DocumentSnapshot? matchedVehicle;

      for (var doc in vehiclesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final vehicleName = data['vehicle_name'] ?? '';
        final vehicleType = data['vehicle_type'] ?? '';
        
        // Try to match by vehicle name first, then type
        if (vehicleName.toLowerCase() == widget.booking.vehicleName.toLowerCase() ||
            vehicleType.toLowerCase() == widget.booking.vehicleType.toLowerCase()) {
          matchedVehicle = doc;
          break;
        }
      }

      // If no match found, use the first vehicle
      matchedVehicle ??= vehiclesSnapshot.docs.first;
      final data = matchedVehicle.data() as Map<String, dynamic>;

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
    } catch (e) {
      // Silently handle error - vehicle might not have a photo
      print('Error loading vehicle photo: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildCarImageSection(),
                  const SizedBox(height: 20),
                  _buildBookingDetailsCard(),
                  const SizedBox(height: 20),
                  _buildServicesCard(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          BottomNavbar(
            currentIndex: 1, // Services tab
            onTap: (index) {
              if (index != 1) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 100 + MediaQuery.of(context).padding.top,
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 25, left: 22, right: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF282828)),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Services Details',
                style: TextStyle(
                  color: Color(0xFF282828),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildCarImageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 122,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Car model and number at left top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 17, top: 10, right: 17),
            child: Row(
              children: [
                Text(
                  '| ${widget.booking.vehicleType} | ${widget.booking.vehicleName}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ],
            ),
          ),
          // Centered car image with circular background
          Expanded(
            child: Center(
              child: Container(
                width: 135,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular background behind the car
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    // Car image on top
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildVehicleImage(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _carImageFallback() {
    return Container(
      width: 135,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.directions_car,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Booking ID', widget.booking.id ?? '-'),
            const SizedBox(height: 8),
            _buildDetailRow('Location📍', 'Block A, A-3-3A, Ativo Plaza, Bandar Sri Damansara, 52200 Kuala Lumpur, Selangor'),
            const SizedBox(height: 8),
            _buildDetailRow('Date 🕒', _formatDateTime(widget.booking.preferredDateTime)),
            const SizedBox(height: 14),
            // Divider line
            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFDADADA),
            ),
            const SizedBox(height: 14),
            _buildDetailRow('Status 📌', _titleCase(widget.booking.status)),
            const SizedBox(height: 8),
            _buildDetailRow('Payment 💳', '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 100, maxWidth: 130),
          child: Text(
            '$label :',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.3,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services🔧 :',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Source Sans Pro',
              ),
            ),
            const SizedBox(height: 16),
            ..._buildServiceRows(),
            const SizedBox(height: 20),
            // Divider line
            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFDADADA),
            ),
            const SizedBox(height: 20),
            // Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧾 Total Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
                Text(
                  _formatCurrency(widget.booking.totalAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(String service, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            service,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 60),
          child: Text(
            price,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildServiceRows() {
    final items = widget.booking.serviceBreakdown;
    if (items.isEmpty) {
      final text = widget.booking.serviceType.isNotEmpty ? widget.booking.serviceType : 'Car services';
      return [
        _buildServiceRow(text, _formatCurrency(widget.booking.totalAmount)),
      ];
    }
    return [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildServiceRow(
            ((item['serviceName'] as String?) ?? 'Service').trim(),
            _formatCurrency(((item['total'] as num?) ?? (item['basePrice'] as num?) ?? 0).toDouble()),
          ),
        ),
    ];
  }

  String _formatDateTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = two(dt.hour);
    final m = two(dt.minute);
    return '${two(dt.day)} ${months[(dt.month - 1).clamp(0,11)]} ${dt.year} – $h:$m';
  }

  String _formatCurrency(double amount) {
    return 'RM ' + amount.toStringAsFixed(2);
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Reschedule button
          Expanded(
            child: Container(
              height: 39.94,
              decoration: BoxDecoration(
                color: const Color(0xFF457AE5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final result = await Navigator.push<BookingModel?>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Booking(initialBooking: widget.booking),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        // Refresh UI with updated booking
                        // Note: booking id preserved in booking screen update path
                        // Here we simply rebuild with new data
                      });
                    }
                  },
                  child: const Center(
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Source Sans Pro',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Cancel Booking button
          Expanded(
            child: Container(
              height: 39.94,
              decoration: BoxDecoration(
                color: const Color(0xFFE54545),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    // Handle cancel booking action
                    _showCancelDialog();
                  },
                  child: const Center(
                    child: Text(
                      'Cancel Booking',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Source Sans Pro',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final id = widget.booking.id;
                if (id != null) {
                  final ok = await BookingService.deleteBooking(id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? 'Booking cancelled successfully' : 'Failed to cancel booking'),
                        backgroundColor: ok ? AppColors.app_green : const Color(0xFFE74C3C),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    await Future.delayed(const Duration(milliseconds: 300));
                    Navigator.of(context).pop(true);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot cancel: missing booking ID'),
                        backgroundColor: Color(0xFFE74C3C),
                      ),
                    );
                  }
                }
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleImage() {
    // Priority: Blob data > URL > fallback asset
    if (_vehiclePhotoData != null) {
      return Image.memory(
        _vehiclePhotoData!,
        width: 135,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _carImageFallback();
        },
      );
    }
    
    if (_vehiclePhotoUrl != null && _vehiclePhotoUrl!.trim().isNotEmpty) {
      return Image.network(
        _vehiclePhotoUrl!,
        width: 135,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _carImageFallback();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 135,
            height: 78,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
          );
        },
      );
    }
    
    return Image.asset(
      'assets/images/cars/car_details_image.png',
      width: 135,
      height: 78,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _carImageFallback();
      },
    );
  }
}
