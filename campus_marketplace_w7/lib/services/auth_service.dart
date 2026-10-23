import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  // ดึง User ปัจจุบัน
  User? get currentUser => _auth.currentUser;

  // Stream ฟังสถานะการล็อกอิน
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 1. สมัครสมาชิกด้วย Email / Password
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception(
            'ยังไม่ได้เปิดใช้งาน Email/Password ใน Firebase Console (ไปที่ Authentication > Sign-in method)');
      }
      throw Exception(_translateErrorCode(e.code, e.message));
    }
  }

  // 2. เข้าสู่ระบบด้วย Email / Password
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
        throw Exception(
            'ยังไม่ได้เปิดใช้งาน Email/Password ใน Firebase Console (ไปที่ Authentication > Sign-in method)');
      }
      throw Exception(_translateErrorCode(e.code, e.message));
    }
  }

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  // เข้าสู่ระบบด้วย Google
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code, e.message));
    }
  }

  // 3. ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ฟังก์ชัน แปลง Error Code จาก Firebase ให้เป็นภาษาไทย
  String _translateErrorCode(String code, [String? message]) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานในระบบแล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ในระบบ';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'invalid-credential':
        return 'ข้อมูลยืนยันตัวตนไม่ถูกต้องหรือหมดอายุ กรุณาลองใหม่อีกครั้ง';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณาลองใหม่ในภายหลัง';
      case 'network-request-failed':
        return 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ';
      default:
        if (message != null && message.contains('CONFIGURATION_NOT_FOUND')) {
          return 'ยังไม่ได้เปิดใช้งาน Sign-in provider ใน Firebase Console';
        }
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน ($code)';
    }
  }
}
