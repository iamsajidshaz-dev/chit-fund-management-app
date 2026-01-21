import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/customer_model.dart';
import '../../models/payment_model.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedMonth;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _generateAvailableMonths();
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _generateAvailableMonths() {
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1, now.month);
    final endDate = DateTime(now.year + 1, now.month);

    _availableMonths = [];
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      _availableMonths.add(DateFormat('yyyy-MM').format(current));
      current = DateTime(current.year, current.month + 1);
    }
    
    _availableMonths = _availableMonths.reversed.toList();
  }

  bool _isCurrentMonth(String month) {
    return month == DateFormat('yyyy-MM').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
      ),
      body: Column(
        children: [
          // Month Selector and Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                // Month Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            items: _availableMonths.map((month) {
                              final monthDate = DateTime.parse('$month-01');
                              final isCurrent = _isCurrentMonth(month);
                              
                              return DropdownMenuItem(
                                value: month,
                                child: Row(
                                  children: [
                                    Text(
                                      DateFormat('MMMM yyyy').format(monthDate),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'CURRENT',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedMonth = value);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Summary Stats
                FutureBuilder<double>(
                  future: _firestoreService.getTotalCollectedAmount(_selectedMonth!),
                  builder: (context, totalSnapshot) {
                    return StreamBuilder<List<PaymentModel>>(
                      stream: _firestoreService.getPaymentsByMonth(_selectedMonth!),
                      builder: (context, paymentsSnapshot) {
                        final total = totalSnapshot.data ?? 0;
                        final paidCount = paymentsSnapshot.data
                            ?.where((p) => p.status == 'paid')
                            .length ?? 0;
                        
                        return Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Collected',
                                '₹${total.toStringAsFixed(0)}',
                                Icons.currency_rupee,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Paid Customers',
                                '$paidCount',
                                Icons.people,
                                Colors.blue,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Add Payment Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _showAddPaymentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment for Customer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          // Customer Payment List
          Expanded(
            child: StreamBuilder<List<CustomerModel>>(
              stream: _firestoreService.getCustomers(),
              builder: (context, customerSnapshot) {
                if (customerSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!customerSnapshot.hasData || customerSnapshot.data!.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }

                final allCustomers = customerSnapshot.data!;

                return StreamBuilder<List<PaymentModel>>(
                  stream: _firestoreService.getPaymentsByMonth(_selectedMonth!),
                  builder: (context, paymentSnapshot) {
                    if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final payments = paymentSnapshot.data ?? [];
                    
                    // Separate paid and unpaid customers
                    final paidCustomers = <CustomerModel>[];
                    final unpaidCustomers = <CustomerModel>[];
                    
                    for (var customer in allCustomers) {
                      final payment = payments.firstWhere(
                        (p) => p.customerId == customer.id,
                        orElse: () => PaymentModel(
                          id: '',
                          customerId: customer.id,
                          customerName: customer.name,
                          amount: customer.monthlyAmount,
                          month: _selectedMonth!,
                          status: 'pending',
                        ),
                      );
                      
                      if (payment.status == 'paid') {
                        paidCustomers.add(customer);
                      } else {
                        unpaidCustomers.add(customer);
                      }
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (paidCustomers.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Paid Customers',
                            paidCustomers.length,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          ...paidCustomers.map((customer) {
                            final payment = payments.firstWhere(
                              (p) => p.customerId == customer.id,
                            );
                            return _buildPaymentCard(customer, payment);
                          }),
                          const SizedBox(height: 24),
                        ],
                        if (unpaidCustomers.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Pending Payments',
                            unpaidCustomers.length,
                            Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          ...unpaidCustomers.map((customer) {
                            final payment = payments.firstWhere(
                              (p) => p.customerId == customer.id,
                              orElse: () => PaymentModel(
                                id: '',
                                customerId: customer.id,
                                customerName: customer.name,
                                amount: customer.monthlyAmount,
                                month: _selectedMonth!,
                                status: 'pending',
                              ),
                            );
                            return _buildPaymentCard(customer, payment);
                          }),
                        ],
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.label, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(CustomerModel customer, PaymentModel payment) {
    final isPaid = payment.status == 'paid';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isPaid ? Colors.green[100] : Colors.orange[100],
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? Colors.green : Colors.orange,
                size: 28,
              ),
            ),
            if (customer.isBlocked)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (customer.hasWon)
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('₹${customer.monthlyAmount.toStringAsFixed(0)}'),
            if (payment.paidAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Paid on ${DateFormat('dd MMM yyyy, hh:mm a').format(payment.paidAt!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'toggle') {
                  _updatePayment(customer, !isPaid);
                } else if (value == 'edit') {
                  _showEditPaymentDialog(customer, payment);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.cancel : Icons.check_circle,
                        size: 20,
                        color: isPaid ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(isPaid ? 'Mark Unpaid' : 'Mark Paid'),
                    ],
                  ),
                ),
                if (isPaid)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPaymentDialog() async {
    final customers = await _firestoreService.getCustomers().first;
    final payments = await _firestoreService.getPaymentsByMonth(_selectedMonth!).first;
    
    CustomerModel? selectedCustomer;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CustomerModel>(
                decoration: const InputDecoration(
                  labelText: 'Select Customer',
                  border: OutlineInputBorder(),
                ),
                initialValue: selectedCustomer,
                items: customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text(customer.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedCustomer = value);
                },
              ),
              const SizedBox(height: 16),
              if (selectedCustomer != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount: ₹${selectedCustomer!.monthlyAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Month: ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}',
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCustomer != null
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedCustomer != null) {
      // Check if payment already exists
      final existingPayment = payments.firstWhere(
        (p) => p.customerId == selectedCustomer!.id && p.status == 'paid',
        orElse: () => PaymentModel(
          id: '',
          customerId: '',
          customerName: '',
          amount: 0,
          month: _selectedMonth!,
          status: 'pending',
        ),
      );

      if (existingPayment.id.isNotEmpty) {
        // Payment already exists
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text('Payment Exists'),
                ],
              ),
              content: Text(
                'Payment for ${selectedCustomer!.name} already exists for ${DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01'))}.\n\nPaid on: ${DateFormat('dd MMM yyyy, hh:mm a').format(existingPayment.paidAt!)}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await _updatePayment(selectedCustomer!, true);
    }
  }

  Future<void> _showEditPaymentDialog(
      CustomerModel customer, PaymentModel payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Payment - ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₹${payment.amount.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Text(
              'Paid on: ${payment.paidAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(payment.paidAt!) : 'N/A'}',
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Mark as Unpaid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updatePayment(customer, false);
    }
  }

  Future<void> _updatePayment(CustomerModel customer, bool isPaid) async {
    try {
      await _firestoreService.updatePayment(
        customer.id,
        _selectedMonth!,
        isPaid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPaid
                  ? 'Payment marked as paid for ${customer.name}'
                  : 'Payment marked as pending for ${customer.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}