import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      throw Exception(_translateErrorCode(e.code));
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
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // 3. ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ฟังก์ชัน แปลง Error Code จาก Firebase ให้เป็นภาษาไทย
  String _translateErrorCode(String code) {
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
        return 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง กรุณาตรวจสอบอีเมลและรหัสผ่าน';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบหลายครั้งเกินไป กรุณาลองใหม่ในภายหลัง';
      default:
        return 'เกิดข้อผิดพลาดในการยืนยันตัวตน ($code)';
    }
  }
}