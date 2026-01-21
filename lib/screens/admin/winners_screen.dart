import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/winner_model.dart';

class WinnersScreen extends StatefulWidget {
  const WinnersScreen({super.key});

  @override
  State<WinnersScreen> createState() => _WinnersScreenState();
}

class _WinnersScreenState extends State<WinnersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Winners'),
      ),
      body: StreamBuilder<List<WinnerModel>>(
        stream: _firestoreService.getWinners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text('No winners yet'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _pickWinner,
                    icon: const Icon(Icons.casino),
                    label: const Text('Pick Winner'),
                  ),
                ],
              ),
            );
          }

          final winners = snapshot.data!;

          return Column(
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Winners can only be picked after 20th of each month. Each month can have only one winner.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Pick Winner Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _pickWinner,
                  icon: const Icon(Icons.casino),
                  label: const Text('Pick New Winner'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),
              // Winners List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: winners.length,
                  itemBuilder: (context, index) {
                    final winner = winners[index];
                    return _buildWinnerCard(winner, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWinnerCard(WinnerModel winner, int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: index == 0
                ? [Colors.amber[100]!, Colors.amber[50]!]
                : [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: index == 0 ? Colors.amber : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          winner.customerName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Round ${winner.chitRound}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Delete Menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteWinner(winner);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete & Redraw'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    'Month',
                    DateFormat('MMM yyyy').format(
                      DateTime.parse('${winner.month}-01'),
                    ),
                    Icons.calendar_today,
                  ),
                  _buildInfoItem(
                    'Amount',
                    '₹${winner.totalAmount.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                  ),
                  _buildInfoItem(
                    'Date',
                    DateFormat('dd MMM').format(winner.selectedAt),
                    Icons.schedule,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _pickWinner() async {
    // Check if today is at least 20th
    final now = DateTime.now();
    if (now.day < 20) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Too Early'),
            ],
          ),
          content: Text(
            'Winners can only be picked after the 20th of each month.\n\nToday is ${DateFormat('dd MMMM yyyy').format(now)}.\n\nPlease wait until 20th ${DateFormat('MMMM').format(now)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final monthController = TextEditingController(
      text: DateFormat('yyyy-MM').format(DateTime.now()),
    );

    // Check if winner already exists for this month
    final winners = await _firestoreService.getWinners().first;
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    final existingWinner = winners.firstWhere(
      (w) => w.month == currentMonth,
      orElse: () => WinnerModel(
        id: '',
        customerId: '',
        customerName: '',
        month: '',
        chitRound: 0,
        totalAmount: 0,
        selectedAt: DateTime.now(),
      ),
    );

    if (existingWinner.id.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text('Winner Already Exists'),
            ],
          ),
          content: Text(
            'A winner has already been selected for ${DateFormat('MMMM yyyy').format(DateTime.parse('$currentMonth-01'))}.\n\nWinner: ${existingWinner.customerName}\n\nIf you want to pick a new winner, please delete the existing winner first using the menu (⋮) option.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick Winner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the month for winner selection:'),
            const SizedBox(height: 16),
            TextField(
              controller: monthController,
              decoration: const InputDecoration(
                labelText: 'Month (yyyy-MM)',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  monthController.text = DateFormat('yyyy-MM').format(picked);
                }
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Winner will receive:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('₹50,000 (Total scheme amount)'),
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
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pick Winner'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.selectRandomWinner(monthController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Winner selected successfully!'),
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

  Future<void> _deleteWinner(WinnerModel winner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Winner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this winner?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Winner: ${winner.customerName}'),
            Text('Month: ${DateFormat('MMMM yyyy').format(DateTime.parse('${winner.month}-01'))}'),
            Text('Amount: ₹${winner.totalAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: After deletion, you can pick a new winner for this month.',
                style: TextStyle(fontSize: 12),
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteWinner(winner.id, winner.customerId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Winner deleted successfully. You can now pick a new winner.'),
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
}