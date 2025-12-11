import 'dart:math';

import 'package:assignment/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking_model.dart';
import '../../../models/invoice_model.dart';
import '../../../models/service_model.dart';
import '../../../models/user_model.dart';
import 'invoice_card.dart';

class Billing extends StatefulWidget {
  const Billing({super.key});

  @override
  State<Billing> createState() => _BillingState();
}

class _BillingState extends State<Billing> {
  final Set<String> _processedBookings = <String>{};
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final bookingsRef = FirebaseFirestore.instance.collection('bookings');
  final invoicesRef = FirebaseFirestore.instance.collection('invoices');

  @override
  void initState() {
    super.initState();

    bookingsRef.where('userId', isEqualTo: userId).snapshots().listen((snapshot) async {
      for (var doc in snapshot.docs) {
        final booking = BookingModel.fromMap(doc.data(), doc.id);

        if (booking.status == 'ready_for_collection' && !_processedBookings.contains(booking.id)) {
          final existingInvoiceQuery = await invoicesRef
              .where('bookingId', isEqualTo: booking.id)
              .get();

          // Check if there's already any invoice for this booking (paid or unpaid)
          bool hasAnyInvoice = existingInvoiceQuery.docs.isNotEmpty;

          if (!hasAnyInvoice) {
            _processedBookings.add(booking.id!);

            await FirebaseFirestore.instance.runTransaction((txn) async {
              // Double-check inside transaction to prevent race conditions
              final latestCheckQuery = invoicesRef
                  .where('bookingId', isEqualTo: booking.id)
                  .limit(1);
              
              final latestCheck = await latestCheckQuery.get();

              if (latestCheck.docs.isEmpty) {
                final invoiceId = await generateUniqueInvoiceId();
                final newInvoiceRef = invoicesRef.doc(invoiceId);

                final services = <ServiceItem>[];
                for (int i = 0; i < booking.serviceBreakdown.length; i++) {
                  final item = booking.serviceBreakdown[i];
                  services.add(
                    ServiceItem(
                      serviceItemId: (i + 1).toString(),
                      serviceItemName: item['serviceName'] ?? 'Unknown',
                      price: (item['total'] as num).toDouble(),
                      serviceCategory: item['category'] ?? '',
                    ),
                  );
                }

                final invoice = Invoice(
                  invoiceId: invoiceId,
                  userId: booking.userId,
                  carType: booking.vehicleType,
                  carModel: booking.vehicleName,
                  bookingId: booking.id!,
                  serviceLocation: "Ativo Plaza",
                  serviceDate: booking.preferredDateTime,
                  invoiceDate: DateTime.now(),
                  totalAmount: booking.totalAmount,
                  status: "unpaid",
                  services: services,
                );

                txn.set(newInvoiceRef, invoice.toJson());
                debugPrint("Invoice generated for booking ${booking.id}");
              } else {
                debugPrint("Invoice already exists (txn check) for booking ${booking.id}");
              }
            });
          } else {
            debugPrint("Invoice already exists for booking ${booking.id} - skipping creation");
          }
        }
      }
    });
  }


  Future<String> generateUniqueInvoiceId() async {
    final invoicesRef = FirebaseFirestore.instance.collection('invoices');
    final random = Random();

    String id;
    bool exists = true;

    do {
      // Generate a 6-digit number (e.g. "483920")
      id = (100000 + random.nextInt(900000)).toString();

      // Check if it exists in Firestore
      final snapshot = await invoicesRef.doc(id).get();
      exists = snapshot.exists;
    } while (exists);

    return id;
  }

  String getDueStatus(Invoice invoice) {
    // Calculate due date (7 days after invoice date)
    final dueDate = invoice.invoiceDate.add(const Duration(days: 7));

    // Current date
    final now = DateTime.now();

    // Difference in whole days
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return "Overdue";
    } else if (difference == 0) {
      return "Due today";
    } else {
      return "Due in $difference days";
    }
  }


  Future<void> saveInvoice(Invoice invoice) async {
    final docRef = FirebaseFirestore.instance
        .collection('invoices')
        .doc(invoice.invoiceId);

    await docRef.set(invoice.toJson());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getInvoicesStream(
    String userId,
    String status,
  ) {
    return FirebaseFirestore.instance
        .collection('invoices')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status)
        .snapshots();
  }

  Stream<UserModel?> getUserStream() {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromJson(doc.data()!);
          } else {
            return null;
          }
        });
  }

  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.height * 0.14,
        ),
        child: AppBar(
          title: const Text("Billing"),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outlined, color: AppColors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Info"),
                    content: const Text(
                      "Here you can pay your bills or view your payment history.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(
              MediaQuery.of(context).size.height * 0.2,
            ),
            child: Container(
              color: AppColors.app_green,
              child: Row(
                children: [
                  _buildTab("CURRENT BILL", 0),
                  _buildTab("PAYMENT HISTORY", 1),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: selectedTab,
        children: [_buildCurrentBilling(), _buildPaymentHistory()],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.white : AppColors.app_grey,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                color: isActive ? AppColors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBilling() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<UserModel?>(
      stream: getUserStream(), // first get the user
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData) {
          return const Center(child: Text("User data not found"));
        }

        final user = userSnapshot.data!;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getInvoicesStream(userId, "unpaid"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No current bills"));
            }

            final invoices = snapshot.data!.docs
                .map((doc) => Invoice.fromJson(doc.data()))
                .toList();

            return ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                return InvoiceCard(
                  invoice: invoices[index],
                  user: user,
                  dueDate: getDueStatus(invoices[index]),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentHistory() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<UserModel?>(
      stream: getUserStream(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData) {
          return const Center(child: Text("User data not found"));
        }

        final user = userSnapshot.data!;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: getInvoicesStream(userId, "paid"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No payment history"));
            }

            final invoices = snapshot.data!.docs
                .map((doc) => Invoice.fromJson(doc.data()))
                .toList();

            return ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                return InvoiceCard(
                  invoice: invoices[index],
                  user: user,
                  dueDate: getDueStatus(invoices[index]),
                );
              },
            );
          },
        );
      },
    );
  }
}
