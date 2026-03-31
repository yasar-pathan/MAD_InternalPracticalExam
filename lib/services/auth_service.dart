import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final User? user = credential.user;
    if (user != null) {
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
