import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isActive;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isActive,
  });

  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}