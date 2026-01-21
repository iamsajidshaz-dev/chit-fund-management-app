import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentInfoModel {
  final String id;
  final String upiId;
  final String qrCodeData;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;

  PaymentInfoModel({
    required this.id,
    required this.upiId,
    required this.qrCodeData,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
  });

  factory PaymentInfoModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PaymentInfoModel(
      id: doc.id,
      upiId: data['upiId'] ?? '',
      qrCodeData: data['qrCodeData'] ?? '',
      bankName: data['bankName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      ifscCode: data['ifscCode'] ?? '',
      accountHolderName: data['accountHolderName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'upiId': upiId,
      'qrCodeData': qrCodeData,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
    };
  }
}