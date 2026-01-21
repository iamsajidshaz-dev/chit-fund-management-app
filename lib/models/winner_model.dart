import 'package:cloud_firestore/cloud_firestore.dart';

class WinnerModel {
  final String id;
  final String customerId;
  final String customerName;
  final String month;
  final int chitRound;
  final double totalAmount;
  final DateTime selectedAt;

  WinnerModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.month,
    required this.chitRound,
    required this.totalAmount,
    required this.selectedAt,
  });

  factory WinnerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return WinnerModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      month: data['month'] ?? '',
      chitRound: data['chitRound'] ?? 0,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      selectedAt: (data['selectedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'month': month,
      'chitRound': chitRound,
      'totalAmount': totalAmount,
      'selectedAt': Timestamp.fromDate(selectedAt),
    };
  }
}