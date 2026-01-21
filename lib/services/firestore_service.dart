import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shamazchits/models/registration_code_model.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';
import '../models/winner_model.dart';
import '../models/feedback_model.dart';
import '../models/announcement_model.dart';
import '../models/payment_info_model.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CUSTOMERS
  Stream<List<CustomerModel>> getCustomers() {
    return _firestore
        .collection('customers')
        .orderBy('joinedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromFirestore(doc))
            .toList());
  }

  Future<CustomerModel?> getCustomerByUserId(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('customers')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return CustomerModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> blockUnblockCustomer(String customerId, bool isBlocked) async {
    await _firestore.collection('customers').doc(customerId).update({
      'isBlocked': isBlocked,
    });

    CustomerModel? customer = await getCustomerById(customerId);
    if (customer != null) {
      await _firestore.collection('users').doc(customer.userId).update({
        'isBlocked': isBlocked,
      });
    }
  }

  Future<CustomerModel?> getCustomerById(String customerId) async {
    DocumentSnapshot doc =
        await _firestore.collection('customers').doc(customerId).get();
    if (!doc.exists) return null;
    return CustomerModel.fromFirestore(doc);
  }

  // PAYMENTS
  Stream<List<PaymentModel>> getPaymentsByMonth(String month) {
    return _firestore
        .collection('payments')
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<PaymentModel>> getPaymentsByCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('month', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updatePayment(String customerId, String month, bool isPaid) async {
    CustomerModel? customer = await getCustomerById(customerId);
    if (customer == null) return;

    QuerySnapshot existingPayment = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();

    if (existingPayment.docs.isNotEmpty) {
      await _firestore
          .collection('payments')
          .doc(existingPayment.docs.first.id)
          .update({
        'status': isPaid ? 'paid' : 'pending',
        'paidAt': isPaid ? FieldValue.serverTimestamp() : null,
      });
    } else {
      await _firestore.collection('payments').add({
        'customerId': customerId,
        'customerName': customer.name,
        'amount': customer.monthlyAmount,
        'month': month,
        'status': isPaid ? 'paid' : 'pending',
        'paidAt': isPaid ? FieldValue.serverTimestamp() : null,
      });
    }

    if (isPaid) {
      await _firestore.collection('customers').doc(customerId).update({
        'consecutiveMissedPayments': 0,
      });
    }
  }

  Future<void> checkAndUpdateMissedPayments() async {
    QuerySnapshot customersSnapshot =
        await _firestore.collection('customers').get();

    for (var doc in customersSnapshot.docs) {
      CustomerModel customer = CustomerModel.fromFirestore(doc);
      
      if (customer.consecutiveMissedPayments >= 3) {
        await _firestore.collection('customers').doc(customer.id).update({
          'isEligible': false,
        });
      }
    }
  }

  Future<double> getTotalCollectedAmount(String month) async {
    QuerySnapshot snapshot = await _firestore
        .collection('payments')
        .where('month', isEqualTo: month)
        .where('status', isEqualTo: 'paid')
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
    }
    return total;
  }

  // WINNERS
  Stream<List<WinnerModel>> getWinners() {
    return _firestore
        .collection('winners')
        .orderBy('selectedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WinnerModel.fromFirestore(doc))
            .toList());
  }

  Future<void> selectRandomWinner(String month) async {
    QuerySnapshot paidPayments = await _firestore
        .collection('payments')
        .where('month', isEqualTo: month)
        .where('status', isEqualTo: 'paid')
        .get();

    List<String> eligibleCustomerIds = [];
    for (var doc in paidPayments.docs) {
      String customerId = (doc.data() as Map<String, dynamic>)['customerId'];
      CustomerModel? customer = await getCustomerById(customerId);
      
      if (customer != null &&
          customer.isEligible &&
          !customer.hasWon &&
          !customer.isBlocked) {
        eligibleCustomerIds.add(customerId);
      }
    }

    if (eligibleCustomerIds.isEmpty) {
      throw Exception('No eligible customers for draw');
    }

    Random random = Random();
    String winnerId = eligibleCustomerIds[random.nextInt(eligibleCustomerIds.length)];
    
    await addWinner(winnerId, month);
  }

  Future<void> addWinner(String customerId, String month) async {
    CustomerModel? customer = await getCustomerById(customerId);
    if (customer == null) return;

    // Fixed winning amount: Always 50,000 (10 customers * 5000 per month)
    const double winningAmount = 50000;
    
    QuerySnapshot winnersSnapshot = await _firestore.collection('winners').get();
    int chitRound = winnersSnapshot.docs.length + 1;

    await _firestore.collection('winners').add({
      'customerId': customerId,
      'customerName': customer.name,
      'month': month,
      'chitRound': chitRound,
      'totalAmount': winningAmount,
      'selectedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('customers').doc(customerId).update({
      'hasWon': true,
    });
  }

  Future<void> deleteWinner(String winnerId, String customerId) async {
    // Delete the winner document
    await _firestore.collection('winners').doc(winnerId).delete();
    
    // Update customer's hasWon status back to false
    await _firestore.collection('customers').doc(customerId).update({
      'hasWon': false,
    });
  }

  // FEEDBACK
  Stream<List<FeedbackModel>> getAllFeedback() {
    return _firestore
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<FeedbackModel>> getFeedbackByCustomer(String customerId) {
    return _firestore
        .collection('feedback')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FeedbackModel.fromFirestore(doc))
            .toList());
  }

  Future<void> submitFeedback(String customerId, String customerName, String message) async {
    await _firestore.collection('feedback').add({
      'customerId': customerId,
      'customerName': customerName,
      'message': message,
      'reply': null,
      'createdAt': FieldValue.serverTimestamp(),
      'repliedAt': null,
      'status': 'pending',
    });
  }

  Future<void> replyToFeedback(String feedbackId, String reply) async {
    await _firestore.collection('feedback').doc(feedbackId).update({
      'reply': reply,
      'repliedAt': FieldValue.serverTimestamp(),
      'status': 'replied',
    });
  }

  // ANNOUNCEMENTS
  Stream<List<AnnouncementModel>> getActiveAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<AnnouncementModel>> getAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addAnnouncement(String title, String message) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> updateAnnouncement(String id, String title, String message, bool isActive) async {
    await _firestore.collection('announcements').doc(id).update({
      'title': title,
      'message': message,
      'isActive': isActive,
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _firestore.collection('announcements').doc(id).delete();
  }

  // PAYMENT INFO
  Future<PaymentInfoModel?> getPaymentInfo() async {
    QuerySnapshot snapshot = await _firestore.collection('paymentInfo').limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      await _firestore.collection('paymentInfo').doc('default').set({
        'upiId': '',
        'qrCodeData': '',
        'bankName': '',
        'accountNumber': '',
        'ifscCode': '',
        'accountHolderName': '',
      });
      
      DocumentSnapshot doc = await _firestore.collection('paymentInfo').doc('default').get();
      return PaymentInfoModel.fromFirestore(doc);
    }
    
    return PaymentInfoModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> updatePaymentInfo(PaymentInfoModel info) async {
    await _firestore.collection('paymentInfo').doc('default').set(info.toMap());
  }

  // REGISTRATION CODES

// Generate random code
String generateRegistrationCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return 'SHAMAZ${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
}

// Create new registration code
Future<String> createRegistrationCode(String adminUid, String? notes) async {
  final code = generateRegistrationCode();
  
  await _firestore.collection('registrationCodes').add({
    'code': code,
    'isUsed': false,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': adminUid,
    'usedAt': null,
    'usedBy': null,
    'customerName': null,
    'notes': notes ?? '',
  });
  
  return code;
}

// Get all registration codes
Stream<List<RegistrationCodeModel>> getRegistrationCodes() {
  return _firestore
      .collection('registrationCodes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => RegistrationCodeModel.fromFirestore(doc))
          .toList());
}

// Validate registration code
Future<bool> validateRegistrationCode(String code) async {
  if (code.trim().isEmpty) return false;
  
  QuerySnapshot snapshot = await _firestore
      .collection('registrationCodes')
      .where('code', isEqualTo: code.trim().toUpperCase())
      .where('isUsed', isEqualTo: false)
      .limit(1)
      .get();
  
  return snapshot.docs.isNotEmpty;
}

// Mark code as used
Future<void> markCodeAsUsed(String code, String userId, String customerName) async {
  QuerySnapshot snapshot = await _firestore
      .collection('registrationCodes')
      .where('code', isEqualTo: code.trim().toUpperCase())
      .limit(1)
      .get();
  
  if (snapshot.docs.isNotEmpty) {
    await _firestore
        .collection('registrationCodes')
        .doc(snapshot.docs.first.id)
        .update({
      'isUsed': true,
      'usedAt': FieldValue.serverTimestamp(),
      'usedBy': userId,
      'customerName': customerName,
    });
  }
}

// Delete registration code
Future<void> deleteRegistrationCode(String codeId) async {
  await _firestore.collection('registrationCodes').doc(codeId).delete();
}
}