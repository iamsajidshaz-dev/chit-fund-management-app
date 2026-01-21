import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerProfileScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                customer.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              customer.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              customer.email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard('Personal Information', [
              _buildInfoRow(Icons.phone, 'Phone', customer.phone),
              _buildInfoRow(
                Icons.calendar_today,
                'Member Since',
                DateFormat('dd MMM yyyy').format(customer.joinedDate),
              ),
            ]),
            const SizedBox(height: 16),
            _buildInfoCard('Chit Information', [
              _buildInfoRow(
                Icons.currency_rupee,
                'Monthly Amount',
                '₹${customer.monthlyAmount.toStringAsFixed(0)}',
              ),
              _buildInfoRow(
                Icons.emoji_events,
                'Won Prize',
                customer.hasWon ? 'Yes' : 'Not Yet',
              ),
              _buildInfoRow(
                Icons.check_circle,
                'Eligibility Status',
                customer.isEligible ? 'Eligible' : 'Ineligible',
              ),
              if (customer.consecutiveMissedPayments > 0)
                _buildInfoRow(
                  Icons.warning,
                  'Missed Payments',
                  '${customer.consecutiveMissedPayments} consecutive',
                  color: Colors.orange,
                ),
            ]),
            const SizedBox(height: 16),
            if (!customer.isEligible)
              Card(
                elevation: 0,
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red[300]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your account is currently ineligible due to 3 or more consecutive missed payments. Please contact the administrator.',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}