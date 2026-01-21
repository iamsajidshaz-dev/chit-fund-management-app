import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final double monthlyAmount;
  final DateTime joinedDate;
  final bool isBlocked;
  final bool hasWon;
  final int consecutiveMissedPayments;
  final bool isEligible;

  CustomerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.monthlyAmount,
    required this.joinedDate,
    required this.isBlocked,
    required this.hasWon,
    required this.consecutiveMissedPayments,
    required this.isEligible,
  });

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CustomerModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      monthlyAmount: (data['monthlyAmount'] ?? 0).toDouble(),
      joinedDate: (data['joinedDate'] as Timestamp).toDate(),
      isBlocked: data['isBlocked'] ?? false,
      hasWon: data['hasWon'] ?? false,
      consecutiveMissedPayments: data['consecutiveMissedPayments'] ?? 0,
      isEligible: data['isEligible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'monthlyAmount': monthlyAmount,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'isBlocked': isBlocked,
      'hasWon': hasWon,
      'consecutiveMissedPayments': consecutiveMissedPayments,
      'isEligible': isEligible,
    };
  }
}