import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationCodeModel {
  final String id;
  final String code;
  final bool isUsed;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? usedAt;
  final String? usedBy;
  final String? customerName;
  final String? notes;

  RegistrationCodeModel({
    required this.id,
    required this.code,
    required this.isUsed,
    required this.createdAt,
    required this.createdBy,
    this.usedAt,
    this.usedBy,
    this.customerName,
    this.notes,
  });

  factory RegistrationCodeModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return RegistrationCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      isUsed: data['isUsed'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      usedAt: data['usedAt'] != null 
          ? (data['usedAt'] as Timestamp).toDate() 
          : null,
      usedBy: data['usedBy'],
      customerName: data['customerName'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'isUsed': isUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedBy': usedBy,
      'customerName': customerName,
      'notes': notes,
    };
  }
}