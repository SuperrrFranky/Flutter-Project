import 'package:assignment/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../../models/booking_model.dart';
import '../../../services/booking_service.dart';
import '../main_navigation_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  String? userName;
  bool isLoading = true;
  bool isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = await BookingService.getCurrentUser();
      if (mounted) {
        setState(() {
          userName = user?.userName ?? 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    // Show confirmation dialog
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && widget.booking.id != null) {
      setState(() {
        isCancelling = true;
      });

      try {
        final success = await BookingService.deleteBooking(widget.booking.id!);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Navigate back to home after showing success message
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  (route) => false,
                );
              }
            });
            await NotificationService.cancelReminderNotification(widget.booking.id.hashCode);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to cancel booking. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isCancelling = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF282828)),
          onPressed: () {

            // Hard redirect to home (initial screen)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          'Booking Confirmed',
          style: TextStyle(
            color: Color(0xFF282828),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Your booking has been submitted successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF282828),
                  ),
                ),
                const SizedBox(height: 16),
                if (isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  _row('Customer name', userName ?? 'User'),
                  _row('Vehicle type', widget.booking.vehicleType),
                  _row('Vehicle name', widget.booking.vehicleName),
                  _row('Phone number', widget.booking.phoneNumber),
                  _row('Service type', widget.booking.serviceType),
                  _row(
                    'Preferred time',
                    '${widget.booking.preferredDateTime.day}/${widget.booking.preferredDateTime.month}/${widget.booking.preferredDateTime.year} '
                    'at ${widget.booking.preferredDateTime.hour.toString().padLeft(2, '0')}:${widget.booking.preferredDateTime.minute.toString().padLeft(2, '0')}',
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: isCancelling ? null : _cancelBooking,
                          child: isCancelling
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel Booking',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF282828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // Hard redirect to home (initial screen)
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text(
                            'Back to Dashboard',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
