import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/admin_model.dart';
import '../utils/constants.dart';
import '../models/coach_model.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AdminModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final snapshot = await _database.ref('${AppConstants.adminsPath}/$uid').get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return AdminModel.fromMap(uid, data);
      }

      // Not an admin, logout
      await _auth.signOut();
      throw Exception('Access denied. Admin account required.');
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<AdminModel?> getAdminStream(String uid) {
    return _database.ref('${AppConstants.adminsPath}/$uid').onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && snapshot.value != null) {
        return AdminModel.fromMap(uid, Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    });
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No admin found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: $code';
    }
  }

  Future<CoachModel?> createCoach({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required String sportFocus,
    required String branch,
    required List<String> permissions,
    required String createdBy,
  }) async {
    try {
      // Firebase Auth'ta oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Realtime Database'e kaydet - admins path'i altında (aynı auth sistemi)
      final coach = CoachModel(
        uid: uid,
        fullName: fullName,
        email: email.trim(),
        role: role,
        phone: phone,
        sportFocus: sportFocus,
        branch: branch,
        permissions: permissions,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _database.ref('${AppConstants.adminsPath}/$uid').set(coach.toMap());

      // Şu anki admin'den çıkış yap, yeni coach'un girişini bozma
      // Tekrar eski admin'e dön
      // (Bunu yapmasak şu anki admin session'ı yeni coach olur)

      return coach;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Failed to create coach: $e');
    }
  }
}