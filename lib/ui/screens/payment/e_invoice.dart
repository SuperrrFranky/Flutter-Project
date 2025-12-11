import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/invoice_model.dart';
import '../../../models/user_model.dart';

class InvoiceInfo extends StatelessWidget {
  final Invoice invoice;
  final UserModel user;

  const InvoiceInfo({super.key, required this.invoice, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("E-Invoice")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(5),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(15),
                },
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      TableCell(child: Text("")),
                      TableCell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Green System Business Software Sdn Bhd",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.app_green,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            Text("", style: TextStyle(fontSize: 6)),
                            Text(
                              "Email: admin@greenstem.com.my       Line: (6)03 6263 3933",
                              style: TextStyle(fontSize: 6),
                              textAlign: TextAlign.start,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text("E-Invoice", style: TextStyle(fontSize: 12)),
              SizedBox(height: 6),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(3),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2.5),
                },
                children: [
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Name", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          user.userName,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "E-Invoice Code",
                              style: TextStyle(fontSize: 6),
                            ),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          "Invoice#${invoice.invoiceId}",
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Email Address",
                              style: TextStyle(fontSize: 6),
                            ),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          user.address,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Invoice Date", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          "${invoice.invoiceDate}".split('.')[0],
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Contact No", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          user.phoneNo,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Payment Date", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          "${invoice.paymentDate}".split('.')[0],
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Car Type", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          invoice.carType,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Booking ID", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          "#${invoice.bookingId}",
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Car Model", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          invoice.carModel,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Service Location",
                              style: TextStyle(fontSize: 6),
                            ),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          invoice.serviceLocation,
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Payment Method",
                              style: TextStyle(fontSize: 6),
                            ),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          invoice.paymentMethod ?? "-",
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                      TableCell(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Service Date", style: TextStyle(fontSize: 6)),
                            Text(": ", style: TextStyle(fontSize: 6)),
                          ],
                        ),
                      ),
                      TableCell(
                        child: Text(
                          "${invoice.serviceDate}".split('.')[0],
                          style: TextStyle(fontSize: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 1,
                    ), // outline
                  ),
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 8),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1.5),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        children: [
                          TableCell(
                            child: Text(
                              "DESCRIPTION",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 6,
                              ),
                            ),
                          ),
                          TableCell(
                            child: Text("", style: TextStyle(fontSize: 6)),
                          ),
                          TableCell(
                            child: Text(
                              "RATE (MYR)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 6,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Text("", style: TextStyle(fontSize: 4)),
                          ),
                          TableCell(
                            child: Text("", style: TextStyle(fontSize: 4)),
                          ),
                          TableCell(
                            child: Text("", style: TextStyle(fontSize: 4)),
                          ),
                        ],
                      ),
                      ...invoice.services.map(
                        (service) => TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  service.serviceItemName,
                                  style: TextStyle(fontSize: 6),
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text("", style: TextStyle(fontSize: 6)),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Text(
                                  service.price.toStringAsFixed(2),
                                  style: TextStyle(fontSize: 6),
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
                            child: Text("", style: TextStyle(fontSize: 6)),
                          ),
                          TableCell(
                            child: Text("", style: TextStyle(fontSize: 6)),
                          ),
                          TableCell(
                            child: Text(
                              "--------------------",
                              style: TextStyle(fontSize: 6),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("", style: TextStyle(fontSize: 6)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "Subtotal :",
                                style: TextStyle(fontSize: 6),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                ((invoice.totalAmount + (invoice.discount ?? 0)) / 1.05).toStringAsFixed(2),
                                style: TextStyle(fontSize: 6),
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
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("", style: TextStyle(fontSize: 6)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "Discount :",
                                style: TextStyle(fontSize: 6),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                invoice.discount?.toStringAsFixed(2) ?? "-",
                                style: TextStyle(fontSize: 6),
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
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("", style: TextStyle(fontSize: 6)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "Service Tax 5% :",
                                style: TextStyle(fontSize: 6),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                (invoice.totalAmount + (invoice.discount ?? 0) - ((invoice.totalAmount + (invoice.discount ?? 0)) / 1.05)).toStringAsFixed(2),
                                style: TextStyle(fontSize: 6),
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
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text("", style: TextStyle(fontSize: 6)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                "Total Amount :",
                                style: TextStyle(fontSize: 8),
                              ),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                invoice.totalAmount.toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 50),
              Text(
                "A-3-3A, Block A, Ativo Plaza. Bandar Sri Damansara, 52200 Kuala Lumpur.",
                style: TextStyle(fontSize: 6, color: AppColors.app_green),
                textAlign: TextAlign.center,
              ),
              Text(
                "TEL: (6)03 6263 3933   WEBSITE: www.greenstem.com.my",
                style: TextStyle(fontSize: 6, color: AppColors.app_green),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
