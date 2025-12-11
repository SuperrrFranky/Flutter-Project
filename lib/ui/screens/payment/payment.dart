import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Payment extends StatefulWidget {
  final Invoice invoice;
  final UserModel user;
  final String dueDate;

  const Payment({
    super.key,
    required this.invoice,
    required this.user,
    required this.dueDate,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String? _selectedVoucherId;
  double? _selectedVoucherValue;

  void _showVoucherDialog(UserModel user, Invoice invoice) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Voucher Selection",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.userId)
                      .collection("vouchers")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No vouchers available.");
                    }

                    final vouchers = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: vouchers.length,
                      itemBuilder: (context, index) {
                        final doc = vouchers[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final value = data['value'] ?? 0;
                        // final expiredDate = DateTime.parse(
                        //   data['expired_date'],
                        // );
                        final voucherId = doc.id;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Icon(Icons.local_offer, size: 24),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    "RM $value Voucher",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Radio<String>(
                                      value: voucherId,
                                      groupValue: _selectedVoucherId,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedVoucherId = value;
                                          _selectedVoucherValue = data['value']
                                              ?.toDouble();
                                        });
                                        setStateDialog(() {});
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
                TextButton(
                  onPressed: () async {
                    if (_selectedVoucherId != null &&
                        _selectedVoucherValue != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection("invoices")
                            .doc(
                              invoice.invoiceId,
                            ) // assuming invoiceId is the Firestore doc id
                            .update({"discount": _selectedVoucherValue});

                        // Update local state (so UI updates instantly)
                        setState(() {
                          widget.invoice.discount = _selectedVoucherValue;
                        });

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Voucher applied: RM $_selectedVoucherValue",
                            ),
                          ),
                        );
                      } catch (e) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to apply voucher: $e"),
                          ),
                        );
                      }
                    } else {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No voucher selected")),
                      );
                    }
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final user = widget.user;
    final dueDate = widget.dueDate;

    final double grandTotal =
        invoice.totalAmount -
        (invoice.discount ?? 0) +
        (invoice.totalAmount * 0.05);

    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Table(
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Text(
                                "Invoice Code",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightgrey,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Text(
                                "Booking Id",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightgrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Text(
                                "Invoice#${invoice.invoiceId}",
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            TableCell(
                              child: Text(
                                "#${invoice.bookingId}",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Table(
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "TO",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  user.userName,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  user.email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  user.phoneNo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "DESCRIPTION",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "RATE",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.lightgrey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: SizedBox(
                                width: double.infinity, // force full width
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: 2,
                                ),
                              ),
                            ),
                            TableCell(
                              child: SizedBox(
                                width: double.infinity,
                                child: Divider(
                                  color: Colors.grey,
                                  thickness: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...invoice.services.map(
                          (service) => TableRow(
                            children: [
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    service.serviceItemName,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              TableCell(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    service.price.toStringAsFixed(2),
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: SizedBox(
                                width: double.infinity, // force full width
                                child: Divider(
                                  color: AppColors.lightgrey,
                                  thickness: 2,
                                ),
                              ),
                            ),
                            TableCell(
                              child: SizedBox(
                                width: double.infinity,
                                child: Divider(
                                  color: AppColors.lightgrey,
                                  thickness: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  "Subtotal",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  invoice.totalAmount.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  "Discount",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  invoice.discount?.toStringAsFixed(2) ?? "-",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  "Service Tax 5%",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 3),
                                child: Text(
                                  (invoice.totalAmount * 0.05).toStringAsFixed(
                                    2,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.lightgrey,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  "GRAND TOTAL",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.app_green,
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Text(
                                  "MYR ${grandTotal.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.app_green,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 10,
                ),
                child: InkWell(
                  onTap: () {
                    _showVoucherDialog(user, invoice); // pass current user id
                  },
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // children: const [Text("App Voucher"), Text(">")],
                    children: [
                      Expanded(flex: 5, child: Text("App Voucher")),
                      Expanded(
                        flex: 5,
                        child: Text(
                          invoice.discount == null
                              ? ""
                              : "-MYR${invoice.discount!.toStringAsFixed(2)}",
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(">", textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Table(
                      children: [
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  "PAY WITH",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightgrey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.app_green,
                                      width: 1,
                                    ), // outline
                                  ),
                                  child: Text("Credit / Debit Card"),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.height * 0.14,
        color: AppColors.white,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: SizedBox.expand(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MYR ${grandTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          dueDate,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.lightgrey,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection("invoices")
                                  .doc(widget.invoice.invoiceId)
                                  .update({
                                    "status": "paid",
                                    "paymentDate": DateTime.now(),
                                    "paymentMethod": "Credit / Debit Card",
                                    "totalAmount": grandTotal,
                                  });

                              int pointsToAdd = (grandTotal / 10).floor();

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(widget.user.userId)
                                  .update({
                                    "point": FieldValue.increment(pointsToAdd),
                                  });

                              // await FirebaseFirestore.instance
                              //     .collection("bookings")
                              //     .doc(widget.invoice.bookingId)
                              //     .update({"status": "completed"});

                              if (_selectedVoucherId != null) {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(widget.user.userId)
                                    .collection("vouchers")
                                    .doc(_selectedVoucherId)
                                    .delete();
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Payment successful!"),
                                ),
                              );

                              Navigator.pop(context, true); // Return true to indicate payment completed
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Payment failed: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.app_green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            "PAY NOW",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}