import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final String month;
  final DateTime? paidAt;
  final String status;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.month,
    this.paidAt,
    required this.status,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      month: data['month'] ?? '',
      paidAt: data['paidAt'] != null ? (data['paidAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'month': month,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'status': status,
    };
  }
}