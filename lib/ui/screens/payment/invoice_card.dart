import 'package:assignment/ui/screens/payment/e_invoice.dart';
import 'package:assignment/ui/screens/payment/payment.dart';
import 'package:flutter/material.dart';
import '../../../models/invoice_model.dart';
import '../../../models/user_model.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final UserModel user;
  final String dueDate;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.user,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          if (invoice.status == "paid") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceInfo(invoice: invoice, user: user),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Payment(invoice: invoice, user: user, dueDate: dueDate),
              ),
            );
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: const Text("Car Service Bill", style: TextStyle(fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text("#${invoice.bookingId}"),
              const SizedBox(height: 4),
              Text(
                invoice.status == "unpaid"
                    ? (dueDate == "Overdue" ? "Overdue" : "Due Date: ${invoice.invoiceDate.add(const Duration(days: 7)).toLocal().toString().split(" ")[0]}")
                    : "E-Invoice: #${invoice.invoiceId}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "MYR ${invoice.totalAmount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: invoice.status == "paid"
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  invoice.status == "paid" ? "Paid" : "Pending",
                  style: TextStyle(
                    fontSize: 12,
                    color: invoice.status == "paid"
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
