import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>> getUserData() async {
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!doc.exists) {
      throw Exception('User data not found');
    }

    return doc.data() as Map<String, dynamic>;
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
    String name,
    String phone,
    double monthlyAmount,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': 'customer',
        'isBlocked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('customers').add({
        'userId': result.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'monthlyAmount': monthlyAmount,
        'joinedDate': FieldValue.serverTimestamp(),
        'isBlocked': false,
        'hasWon': false,
        'consecutiveMissedPayments': 0,
        'isEligible': true,
      });

      return result;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}