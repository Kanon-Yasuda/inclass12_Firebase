import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<UserCredential> register(String email, String password) {
        return _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
        );
    }

    Future<UserCredential> signIn(String email, String password) {
        return _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
        );
    }

    Future<void> signOut() {
        return _auth.signOut();
    }

    late final Stream<User?> authStateChanges = _auth.authStateChanges();

    Future<void> changePassword(String newPassword) async {
        final user = _auth.currentUser;
        if (user == null) {
            throw StateError('A signed-in user is required to change a password.');
        }
        await user.updatePassword(newPassword);
    }

    User? get currentUser => _auth.currentUser;
}