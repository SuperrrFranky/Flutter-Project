import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking_model.dart';
import '../../../models/invoice_model.dart';
import '../../../models/user_model.dart';
import '../payment/payment.dart';
import 'progress.dart';

class ProgressServiceListScreen extends StatelessWidget {
  const ProgressServiceListScreen({super.key});

  Stream<List<BookingModel>> _streamUserReadyBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final now = DateTime.now();
      final list = snap.docs
          .map((d) => BookingModel.fromMap(d.data(), d.id))
          .where((b) => b.status.toLowerCase() != 'completed')
          .where((b) => b.preferredDateTime.isBefore(now) || b.preferredDateTime.isAtSameMomentAs(now))
          .toList();
      
      // Auto-update pending bookings to in_inspection when preferredDateTime arrives
      for (final booking in list) {
        if (booking.status == 'pending' && now.isAfter(booking.preferredDateTime)) {
          _updateBookingStatus(booking);
        }
      }
      
      list.sort((a, b) => a.preferredDateTime.compareTo(b.preferredDateTime));
      return list;
    });
  }

  // Auto-update status to 'in_inspection' when preferredDateTime arrives
  Future<void> _updateBookingStatus(BookingModel booking) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(booking.id)
          .update({
        'status': 'in_inspection',
        'lastStatusUpdate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating status to in_inspection: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      appBar: AppBar(
        title: const Text('Service Progress'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _streamUserReadyBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data ?? const <BookingModel>[];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'No services are currently in progress. Check back once your preferred date & time arrives.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final b = items[index];
              return _ProgressCard(booking: b);
            },
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatefulWidget {
  final BookingModel booking;
  const _ProgressCard({required this.booking});

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard> {
  bool _isCheckingPayment = false;
  bool _isInvoicePaid = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking.status.toLowerCase() == 'ready_for_collection') {
      _checkInvoiceStatus();
    }
  }

  Future<void> _checkInvoiceStatus() async {
    if (widget.booking.status.toLowerCase() == 'ready_for_collection') {
      setState(() {
        _isCheckingPayment = true;
      });

      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('invoices')
            .where('bookingId', isEqualTo: widget.booking.id)
            .limit(1)
            .get();
        
        if (querySnapshot.docs.isNotEmpty) {
          final invoice = Invoice.fromJson(querySnapshot.docs.first.data());
          setState(() {
            _isInvoicePaid = invoice.status == 'paid';
            _isCheckingPayment = false;
          });
        } else {
          setState(() {
            _isInvoicePaid = false;
            _isCheckingPayment = false;
          });
        }
      } catch (e) {
        print('Error checking invoice status: $e');
        setState(() {
          _isInvoicePaid = false;
          _isCheckingPayment = false;
        });
      }
    } else {
      setState(() {
        _isCheckingPayment = false;
      });
    }
  }

  // Convert status with underscores to user-friendly display name
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'in_inspection':
        return 'IN INSPECTION';
      case 'servicing':
        return 'SERVICING';
      case 'ready_for_collection':
        return 'READY FOR COLLECTION';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  // Format date time for better display
  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  // Get the appropriate action button based on booking status and payment
  Widget _getActionButton(BuildContext context, BookingModel booking) {
    if (booking.status.toLowerCase() == 'ready_for_collection') {
      if (_isCheckingPayment) {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 4),
              Text('Checking...'),
            ],
          ),
        );
      } else if (_isInvoicePaid) {
        return ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ServiceProgressScreen(bookingId: booking.id)),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF29A87A), // Green for view
            foregroundColor: Colors.white,
          ),
          child: const Text('View'),
        );
      } else {
        return ElevatedButton(
          onPressed: () {
            // Navigate to payment screen
            _navigateToPayment(context, booking);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C), // Red color for payment
            foregroundColor: Colors.white,
          ),
          child: const Text('Pay Now'),
        );
      }
    } else {
      return ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ServiceProgressScreen(bookingId: booking.id)),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF29A87A),
          foregroundColor: Colors.white,
        ),
        child: const Text('View'),
      );
    }
  }

  // Navigate to payment screen
  void _navigateToPayment(BuildContext context, BookingModel booking) async {
    try {
      // Get invoice for this booking
      final invoiceQuery = await FirebaseFirestore.instance
          .collection('invoices')
          .where('bookingId', isEqualTo: booking.id)
          .limit(1)
          .get();

      if (invoiceQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice not found. Please contact support.')),
        );
        return;
      }

      final invoice = Invoice.fromJson(invoiceQuery.docs.first.data());

      // Get user data
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(booking.userId)
          .get();

      if (!userQuery.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found. Please contact support.')),
        );
        return;
      }

      final user = UserModel.fromJson(userQuery.data()!);

      // Navigate to payment screen
      if (context.mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => Payment(
              invoice: invoice,
              user: user,
              dueDate: 'Due: ${DateTime.now().add(const Duration(days: 7)).toString().split(' ')[0]}',
            ),
          ),
        );
        
        // Refresh payment status when returning from payment screen
        if (result == true || result == null) {
          _checkInvoiceStatus();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFD4EEE5), shape: BoxShape.circle),
          child: const Icon(Icons.directions_car, color: Colors.black87),
        ),
        title: Text(
          widget.booking.vehicleName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Service: ${widget.booking.serviceType}',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Starts: ${_formatDateTime(widget.booking.preferredDateTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _getStatusDisplayName(widget.booking.status),
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _getActionButton(context, widget.booking),
      ),
    );
  }
}


