import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/bottom_navbar.dart';
import '../../../models/booking_model.dart';
import '../../../models/invoice_model.dart';
import '../../../models/vehicle_model.dart';
import '../../../models/user_model.dart';
import '../payment/e_invoice.dart';
import '../payment/payment.dart';

/// CompletedServiceDetailsScreen displays service details with payment information
/// 
/// Usage with Invoice model:
/// ```dart
/// CompletedServiceDetailsScreen(
///   carNumber: 'ABC1234',
///   date: '15 Jan 2024',
///   invoice: invoice, // Pass invoice model for payment details and services
/// )
/// ```
/// 
/// IMPORTANT: This screen is for COMPLETED services only - it MUST receive an invoice parameter
/// 
/// The invoice contains the actual services that were paid for and completed:
/// - Payment method from invoice.paymentMethod  
/// - Services from invoice.services (actual completed services)
/// - Voucher discount from invoice.discount
/// - Final payment totals and details
/// 
/// This screen shows what the customer actually paid for (NOT the booking details)

class CompletedServiceDetailsScreen extends StatefulWidget {
  final String carNumber;
  final String carModel;
  final String date;
  final BookingModel? booking; // when provided, populate details from it
  final Invoice? invoice; // when provided, populate payment details from it
  
  const CompletedServiceDetailsScreen({
    Key? key,
    required this.carNumber,
    required this.date,
    this.carModel = 'Proton X50',
    this.booking,
    this.invoice,
  }) : super(key: key);

  @override
  State<CompletedServiceDetailsScreen> createState() => _CompletedServiceDetailsScreenState();
}

class _CompletedServiceDetailsScreenState extends State<CompletedServiceDetailsScreen> {
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

      // Try to match vehicle by car model from invoice
      String? carModel = widget.invoice?.carModel;
      DocumentSnapshot? matchedVehicle;

      for (var doc in vehiclesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final vehicleName = data['vehicle_name'] ?? '';
        
        // Try to match by vehicle name from invoice
        if (carModel != null && vehicleName.toLowerCase().contains(carModel.toLowerCase())) {
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
                  if (widget.invoice != null) ...[
                    _buildCheckBillingButton(),
                    const SizedBox(height: 20),
                  ],
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
                  'Service Details',
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
                  '| ${widget.invoice?.carModel ?? widget.carModel} | ${widget.invoice?.carType ?? widget.carNumber}',
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
            _buildDetailRow('Invoice ID', widget.invoice?.invoiceId ?? '-'),
            const SizedBox(height: 8),
            _buildDetailRow('Location📍', widget.invoice?.serviceLocation ?? '-'),
            const SizedBox(height: 8),
            _buildDetailRow('Service Date 🕒', widget.invoice != null ? _formatDateTime(widget.invoice!.serviceDate) : widget.date),
            const SizedBox(height: 14),
            // Divider line
            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFDADADA),
            ),
            const SizedBox(height: 14),
            _buildDetailRowWithStatus('Status 📌', _titleCase((widget.invoice?.status ?? 'completed')), widget.invoice?.status == 'paid' ? 'Completed' : 'Pending'),
            const SizedBox(height: 14),
            // Divider line
            Container(
              height: 1,
              width: double.infinity,
              color: const Color(0xFFDADADA),
            ),
            const SizedBox(height: 14),
            // Payment information from invoice
            _buildDetailRow('Method 💳', widget.invoice?.paymentMethod ?? 'Cash'),
            if (widget.invoice?.paymentDate != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Payment Date 📅', _formatDateTime(widget.invoice!.paymentDate!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              height: 1.2,
            ),
            textAlign: TextAlign.start,
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
              height: 1.2,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithColor(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              height: 1.2,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
              height: 1.2,
              fontFamily: 'Source Sans Pro',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowWithStatus(String label, String value, String status, [Color? statusColor]) {
    final color = statusColor ?? const Color(0xFF0F9918);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
              height: 1.2,
            ),
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'Source Sans Pro',
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
              fontFamily: 'Roboto Flex',
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
        padding: const EdgeInsets.all(16),
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
            // Subtotal amount (from invoice only)
            // Services subtotal (before tax and discount)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧾 Subtotal:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
                Text(
                  widget.invoice != null ? _formatCurrency(_calculateSubtotal()) : 'RM 0.00',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ],
            ),
            // Tax (5%)
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📋 Tax (5%):',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
                Text(
                  widget.invoice != null ? _formatCurrency(_calculateTax()) : 'RM 0.00',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Source Sans Pro',
                  ),
                ),
              ],
            ),
            // Show discount if available
            if (widget.invoice?.discount != null && widget.invoice!.discount! > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🎫 Discount:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                      fontFamily: 'Source Sans Pro',
                    ),
                  ),
                  Text(
                    '-${_formatCurrency(widget.invoice!.discount!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                      fontFamily: 'Source Sans Pro',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Divider line
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0xFFDADADA),
              ),
              const SizedBox(height: 8),
              // Final total (from invoice)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Source Sans Pro',
                    ),
                  ),
                  Text(
                    _formatCurrency(widget.invoice!.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Source Sans Pro',
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              // Divider line
              Container(
                height: 1,
                width: double.infinity,
                color: const Color(0xFFDADADA),
              ),
              const SizedBox(height: 8),
              // Final total (from invoice)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Source Sans Pro',
                    ),
                  ),
                  Text(
                    widget.invoice != null ? _formatCurrency(widget.invoice!.totalAmount) : 'RM 0.00',
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
    // ALWAYS use invoice services - this is for completed services that were paid
    if (widget.invoice != null && widget.invoice!.services.isNotEmpty) {
      return [
        for (final service in widget.invoice!.services)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildServiceRow(
              service.serviceCategory.isNotEmpty 
                  ? '${service.serviceItemName}\n${service.serviceCategory}'
                  : service.serviceItemName,
              _formatCurrency(service.price),
            ),
          ),
      ];
    }
    
    // If no invoice data, show a message that invoice is required
    return [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No invoice data available.\nCompleted services should be viewed with invoice details.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return two(dt.day) + ' ' + months[(dt.month - 1).clamp(0,11)] + ' ' + dt.year.toString() + ' – ' + two(dt.hour) + ':' + two(dt.minute);
  }

  String _formatCurrency(double amount) {
    return 'RM ' + amount.toStringAsFixed(2);
  }

  // Calculate subtotal (before tax and discount)
  double _calculateSubtotal() {
    if (widget.invoice == null) return 0.0;
    
    // Invoice totalAmount is final amount after tax and discount
    // Working backwards: totalAmount = (subtotal * 1.05) - discount
    // So: subtotal = (totalAmount + discount) / 1.05
    double totalWithDiscount = widget.invoice!.totalAmount + (widget.invoice!.discount ?? 0);
    return totalWithDiscount / 1.05;
  }

  // Calculate 5% tax
  double _calculateTax() {
    if (widget.invoice == null) return 0.0;
    return _calculateSubtotal() * 0.05;
  }

  String _titleCase(String s) {
    return s
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getPaymentStatusColor() {
    if (widget.invoice?.status == 'paid') {
      return const Color(0xFF0F9918); // Green
    } else if (widget.invoice?.status == 'pending') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
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
          return _buildFallbackImage();
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
          return _buildFallbackImage();
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
    
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/cars/car_details_image.png',
      width: 135,
      height: 78,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 135,
          height: 78,
          color: Colors.grey[300],
          child: Icon(
            Icons.directions_car,
            size: 40,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget _buildCheckBillingButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _navigateToInvoice(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.app_green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Text(
                'Check Billing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Source Sans Pro',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToInvoice() async {
    if (widget.invoice == null) return;

    try {
      // Fetch current user data
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Fetch user model from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        return;
      }

      final userData = UserModel.fromJson(userDoc.data()!);

      // Navigate based on invoice status
      if (widget.invoice!.status == 'paid') {
        // Navigate to invoice details for paid invoices
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceInfo(
              invoice: widget.invoice!,
              user: userData,
            ),
          ),
        );
      } else {
        // Navigate to payment screen for unpaid invoices
        // Calculate due date (typically 30 days from invoice date)
        final dueDate = widget.invoice!.invoiceDate.add(const Duration(days: 30));
        final dueDateString = "${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}/${dueDate.year}";
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Payment(
              invoice: widget.invoice!,
              user: userData,
              dueDate: dueDateString,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to invoice: ${e.toString()}')),
      );
    }
  }
}
