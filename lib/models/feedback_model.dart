import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String customerId;
  final String customerName;
  final String message;
  final String? reply;
  final DateTime createdAt;
  final DateTime? repliedAt;
  final String status;

  FeedbackModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.message,
    this.reply,
    required this.createdAt,
    this.repliedAt,
    required this.status,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      message: data['message'] ?? '',
      reply: data['reply'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      repliedAt: data['repliedAt'] != null ? (data['repliedAt'] as Timestamp).toDate() : null,
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'message': message,
      'reply': reply,
      'createdAt': Timestamp.fromDate(createdAt),
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
      'status': status,
    };
  }
}