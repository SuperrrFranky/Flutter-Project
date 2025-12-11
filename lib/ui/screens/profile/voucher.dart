import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/voucher_model.dart';
import '../../screens/payment/billing.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  static const List<Map<String, int>> _available = [
    {'value': 10, 'points': 100},
    {'value': 50, 'points': 500},
    {'value': 100, 'points': 1000},
  ];

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userDocStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _activeVouchersStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userDocStream = FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      _activeVouchersStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vouchers')
          .where('expired_date', isGreaterThan: DateTime.now().toIso8601String())
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          'Voucher',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Summary Section (live)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _userDocStream,
              builder: (context, snap) {
                final data = snap.data?.data();
                final points = (data != null) ? ((data['point'] as num?)?.toInt() ?? 0) : 0;
                return _buildPointsSummary(points);
              },
            ),
            const SizedBox(height: 24),

            // Active Vouchers (only show when exists)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _activeVouchersStream,
              builder: (context, snap) {
                final hasActive = (snap.data?.docs.isNotEmpty ?? false);
                if (!hasActive) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Active Vouchers'),
                    const SizedBox(height: 12),
                    ...snap.data!.docs.map((d) {
                      final v = VoucherModel.fromJson(d.data());
                      // Auto-delete expired vouchers
                      if (v.expiredDate.isBefore(DateTime.now())) {
                        _deleteExpired(d.id);
                        return const SizedBox.shrink();
                      }
                      final until = v.expiredDate.toLocal().toString().split(' ').first;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActiveVoucherCard(
                          title: 'RM ' + v.value.toString() + ' Voucher',
                          requiredPoints: v.value.toString() + ' pts',
                          validUntil: until,
                          onTap: () => _goToPaymentWithVoucher(d.id, v),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Available Vouchers
            _buildSectionTitle('Available Vouchers'),
            const SizedBox(height: 12),
            ..._available.map((cfg) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAvailableVoucherCard(
                    title: 'RM ' + cfg['value'].toString() + ' Voucher',
                    requiredPoints: cfg['points'].toString() + ' points',
                    onTap: () => _claimVoucher(pointsRequired: cfg['points']!, value: cfg['value']!),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsSummary(int points) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF29A87A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You have :',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  points.toString() + ' Points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Redeem rewards and enjoy discount!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimVoucher({required int pointsRequired, required int value}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
      return;
    }
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final userSnap = await tx.get(userRef);
        final currentPoints = (userSnap.data()?['point'] as num?)?.toInt() ?? 0;
        if (currentPoints < pointsRequired) {
          throw Exception('Not enough points');
        }
        final now = DateTime.now();
        final expiry = now.add(const Duration(days: 30));
        final voucherRef = userRef.collection('vouchers').doc();
        final voucher = VoucherModel(
          voucherId: voucherRef.id,
          userId: uid,
          expiredDate: expiry,
          value: value,
        );
        tx.set(voucherRef, voucher.toJson());
        tx.update(userRef, {'point': currentPoints - pointsRequired});
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher claimed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim failed: ' + e.toString())));
    }
  }

  Future<void> _goToPaymentWithVoucher(String voucherId, VoucherModel voucher) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Simply navigate to payment; do not delete the voucher here
    // Minimal redirect example: go to Billing screen or Payment entry
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Billing()));
  }

  Future<void> _deleteExpired(String voucherId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('vouchers')
          .doc(voucherId)
          .delete();
    } catch (_) {}
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildActiveVoucherCard({
    required String title,
    required String requiredPoints,
    required String validUntil,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Required $requiredPoints',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Valid until: $validUntil',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF29A87A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Use Now',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableVoucherCard({
    required String title,
    required String requiredPoints,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Required $requiredPoints',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Claim',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
