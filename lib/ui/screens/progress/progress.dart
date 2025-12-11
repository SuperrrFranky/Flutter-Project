import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking_model.dart';
import '../../../models/invoice_model.dart';
import '../../../models/user_model.dart';
import '../../../services/booking_service.dart';
import '../payment/payment.dart';

class ServiceProgressScreen extends StatefulWidget {
  final String? bookingId;

  const ServiceProgressScreen({super.key, this.bookingId});

  @override
  State<ServiceProgressScreen> createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  late final Stream<BookingModel?> _bookingStream;
  String? _currentBookingId;

  // Removed unused full mapping to satisfy linter

  // Display-only pipeline (3 statuses only)
  static const List<String> _displayPipeline = <String>[
    'in_inspection',
    'servicing',
    'ready_for_collection',
  ];
  static const Map<String, String> _displayPretty = <String, String>{
    'in_inspection': 'In Inspection',
    'servicing': 'Servicing',
    'ready_for_collection': 'Ready For Collection',
  };

  static const Map<String, String> _latestNotes = <String, String>{
    'pending': 'We are reviewing your booking details.',
    'in_inspection': 'Technician is inspecting the vehicle.',
    'servicing': 'Service is in progress.',
    'ready_for_collection': 'Vehicle is ready for collection.',
    'completed': 'Service completed. Thank you!',
  };

  @override
  void initState() {
    super.initState();
    if (widget.bookingId != null) {
      _bookingStream = FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .snapshots()
          .map((doc) => doc.exists ? BookingModel.fromMap(doc.data()!, doc.id) : null);
      _currentBookingId = widget.bookingId;
    } else {
      // Resolve latest booking for current user without requiring a composite index
      final uid = FirebaseAuth.instance.currentUser?.uid;
      _bookingStream = FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots()
          .map((snap) {
        if (snap.docs.isEmpty) return null;
        // Pick the most recent by createdAt client-side
        QueryDocumentSnapshot<Map<String, dynamic>> latest = snap.docs.first;
        for (final d in snap.docs) {
          final tsLatest = latest.data()['createdAt'];
          final tsD = d.data()['createdAt'];
          final dtLatest = tsLatest is Timestamp ? tsLatest.toDate() : DateTime.tryParse('$tsLatest') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dtD = tsD is Timestamp ? tsD.toDate() : DateTime.tryParse('$tsD') ?? DateTime.fromMillisecondsSinceEpoch(0);
          if (dtD.isAfter(dtLatest)) {
            latest = d;
          }
        }
        _currentBookingId = latest.id;
        return BookingModel.fromMap(latest.data(), latest.id);
      });
    }
  }



  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF282828),
        title: const Text(
          'Real-Time Service Progress',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<BookingModel?>(
        stream: _bookingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }
          _currentBookingId = booking.id ?? _currentBookingId;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VehicleSummaryCard(booking: booking),
                const SizedBox(height: 12),
                _ServiceSummaryCard(booking: booking),
                const SizedBox(height: 16),
                _EstimateRow(),
                const SizedBox(height: 12),
                _Timeline(
                  status: booking.status == 'pending' ? 'in_inspection' : booking.status,
                  pipeline: _displayPipeline,
                  pretty: _displayPretty,
                ),
                const SizedBox(height: 16),
                _LatestUpdateCard(
                  status: booking.status == 'pending' ? 'in_inspection' : booking.status, 
                  latestNotes: _latestNotes, 
                  lastUpdated: DateTime.now()
                ),
                const SizedBox(height: 24),
                _PaymentOrCompleteButton(booking: booking),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VehicleSummaryCard extends StatelessWidget {
  final BookingModel booking;
  const _VehicleSummaryCard({required this.booking});

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFD4EEE5), shape: BoxShape.circle),
              child: const Icon(Icons.directions_car, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.vehicleName.isNotEmpty ? '${booking.vehicleName} - Service' : 'Vehicle',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    booking.vehicleType,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final BookingModel booking;
  const _ServiceSummaryCard({required this.booking});

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFEDE7F6), shape: BoxShape.circle),
              child: const Icon(Icons.handyman, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Type: ${booking.serviceType.isNotEmpty ? booking.serviceType : 'Service'}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (booking.serviceBreakdown.isNotEmpty)
                    Text(
                      'Requested: ${booking.serviceBreakdown.first['serviceName'] ?? booking.serviceType}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  if (booking.totalAmount > 0)
                    Text(
                      'Price estimate: RM${booking.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Icon(Icons.access_time, size: 20),
        SizedBox(width: 8),
        Text('Estimate Completion Time : 4 days', style: TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final String status;
  final List<String> pipeline;
  final Map<String, String> pretty;

  const _Timeline({required this.status, required this.pipeline, required this.pretty});

  @override
  Widget build(BuildContext context) {
    final index = pipeline.indexOf(status.toLowerCase()).clamp(0, pipeline.length - 1);
    return Column(
      children: [
        for (int i = 0; i < pipeline.length; i++)
          _TimelineStep(
            label: pretty[pipeline[i]] ?? pipeline[i],
            active: i <= index,
            last: i == pipeline.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool active;
  final bool last;

  const _TimelineStep({required this.label, required this.active, required this.last});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF2ECC71) : const Color(0xFFBDBDBD),
                  shape: BoxShape.circle,
                ),
              ),
              if (!last)
                Container(
                  width: 4,
                  height: 42,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF2ECC71) : const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.black : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _LatestUpdateCard extends StatelessWidget {
  final String status;
  final Map<String, String> latestNotes;
  final DateTime lastUpdated;

  const _LatestUpdateCard({required this.status, required this.latestNotes, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final text = latestNotes[status.toLowerCase()] ?? 'Status updated.';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDADADA)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.notes, color: Colors.black87),
                SizedBox(width: 8),
                Text('Latest Update:', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            Text('"' + text + '"', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              '(Updated at: ' + _formatTime(lastUpdated) + ')',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    final h = two(dt.hour);
    final m = two(dt.minute);
    return '$h:$m';
  }
}

class _PaymentOrCompleteButton extends StatefulWidget {
  final BookingModel booking;
  const _PaymentOrCompleteButton({required this.booking});

  @override
  State<_PaymentOrCompleteButton> createState() => _PaymentOrCompleteButtonState();
}

class _PaymentOrCompleteButtonState extends State<_PaymentOrCompleteButton> {
  bool _isCheckingPayment = true;
  bool _isInvoicePaid = false;

  @override
  void initState() {
    super.initState();
    _checkInvoiceStatus();
  }

  Future<void> _checkInvoiceStatus() async {
    if (widget.booking.status.toLowerCase() == 'ready_for_collection') {
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

  @override
  Widget build(BuildContext context) {
    final isReady = widget.booking.status.toLowerCase() == 'ready_for_collection';
    if (!isReady) return const SizedBox.shrink();

    if (_isCheckingPayment) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text('Checking Payment...'),
            ],
          ),
        ),
      );
    }

    // Show payment button if not paid, complete button if paid
    if (!_isInvoicePaid) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to payment screen
            _navigateToPayment(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE74C3C), // Red for payment
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Pay Now'),
        ),
      );
    } else {
      // Show complete button if payment is done
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              final updated = widget.booking.copyWith(
                status: 'completed',
                lastStatusUpdate: DateTime.now(),
              );
              await BookingService.updateBooking(updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service completed successfully!')),
                );
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error completing service: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2ECC71), // Green for complete
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Complete Service'),
        ),
      );
    }
  }

  void _navigateToPayment(BuildContext context) async {
    try {
      // Get invoice for this booking
      final invoiceQuery = await FirebaseFirestore.instance
          .collection('invoices')
          .where('bookingId', isEqualTo: widget.booking.id)
          .limit(1)
          .get();

      if (invoiceQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice is being generated. Please try again shortly.')),
        );
        return;
      }


      final invoice = Invoice.fromJson(invoiceQuery.docs.first.data());

      // Get user data
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.userId)
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
}

class _CompleteButtonIfReady extends StatefulWidget {
  final BookingModel booking;
  const _CompleteButtonIfReady({required this.booking});

  @override
  State<_CompleteButtonIfReady> createState() => _CompleteButtonIfReadyState();
}

class _CompleteButtonIfReadyState extends State<_CompleteButtonIfReady> {
  bool _isCheckingPayment = true;
  bool _isInvoicePaid = false;

  @override
  void initState() {
    super.initState();
    _checkInvoiceStatus();
  }

  Future<void> _checkInvoiceStatus() async {
    if (widget.booking.status.toLowerCase() == 'ready_for_collection') {
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

  @override
  Widget build(BuildContext context) {
    final isReady = widget.booking.status.toLowerCase() == 'ready_for_collection';
    if (!isReady) return const SizedBox.shrink();

    if (_isCheckingPayment) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text('Checking Payment...'),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isInvoicePaid ? () async {
          try {
            final updated = widget.booking.copyWith(
              status: 'completed',
              lastStatusUpdate: DateTime.now(),
            );
            await BookingService.updateBooking(updated);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service completed successfully!')),
              );
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error completing service: $e')),
              );
            }
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isInvoicePaid ? const Color(0xFF2ECC71) : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(_isInvoicePaid ? 'Complete Service' : 'Payment Required'),
      ),
    );
  }
}

//progress ui