import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';
import 'package:provider/provider.dart';

class CustomerPaymentHistoryScreen extends StatefulWidget {
  const CustomerPaymentHistoryScreen({super.key});

  @override
  State<CustomerPaymentHistoryScreen> createState() => _CustomerPaymentHistoryScreenState();
}

class _CustomerPaymentHistoryScreenState extends State<CustomerPaymentHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: FutureBuilder<CustomerModel?>(
        future: _firestoreService.getCustomerByUserId(authService.currentUser!.uid),
        builder: (context, customerSnapshot) {
          if (customerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!customerSnapshot.hasData || customerSnapshot.data == null) {
            return const Center(child: Text('Customer data not found'));
          }

          final customer = customerSnapshot.data!;

          return StreamBuilder<List<PaymentModel>>(
            stream: _firestoreService.getPaymentsByCustomer(customer.id),
            builder: (context, paymentsSnapshot) {
              if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!paymentsSnapshot.hasData || paymentsSnapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No payment history yet'),
                    ],
                  ),
                );
              }

              final payments = paymentsSnapshot.data!;
              final paidPayments = payments.where((p) => p.status == 'paid').toList();
              final totalPaid = paidPayments.fold<double>(0, (sum, p) => sum + p.amount);

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Total Paid',
                          '₹${totalPaid.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Months',
                          '${paidPayments.length}',
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: payments.length,
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return _buildPaymentCard(payment);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final isPaid = payment.status == 'paid';
    final monthDate = DateTime.parse('${payment.month}-01');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isPaid ? Icons.check_circle : Icons.pending,
            color: isPaid ? Colors.green : Colors.orange,
            size: 28,
          ),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(monthDate),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('₹${payment.amount.toStringAsFixed(0)}'),
            if (payment.paidAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Paid on ${DateFormat('dd MMM yyyy').format(payment.paidAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isPaid ? 'Paid' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}