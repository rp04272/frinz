import 'package:firebase_auth/firebase_auth.dart';


class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmail({required String email}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: '',
      );
      return userCredential.user;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  Future<User?> registerWithEmail({required String email}) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: '',
      );
      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
      }
      return user;
    } catch (e) {
      print('Error registering with email: $e');
      return null;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      await user?.sendEmailVerification();
    } catch (e) {
      print('Error sending email verification: $e');
    }
  }

  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}
