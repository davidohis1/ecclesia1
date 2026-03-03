import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // Check username uniqueness
      final usernameQuery = await _firestore
          .collection(AppConstants.colUsers)
          .where('username', isEqualTo: username.toLowerCase())
          .get();

      if (usernameQuery.docs.isNotEmpty) {
        throw Exception('Username already taken');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        username: username.toLowerCase(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.colUsers)
          .doc(credential.user!.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await getUserById(credential.user!.uid);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(user.uid)
        .update(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
