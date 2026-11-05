import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    Future<void> changePassword() async {
      final password = TextEditingController();
      final current = TextEditingController();

      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      final oldPassword = current.text;
      final newPassword = password.text;
      current.dispose();
      password.dispose();

      if (save != true) return;

      String message = 'Password updated.';

      try {
        if (newPassword.length < 6) {
          throw Exception('Short password');
        }

        try {
          await auth.changePassword(newPassword);
        } on FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') rethrow;
          final user = auth.currentUser!;
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: oldPassword,
          );
          await user.reauthenticateWithCredential(credential);
          await auth.changePassword(newPassword);
        }
      } catch (_) {
        message = 'Could not update password. Check your passwords.';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${auth.currentUser?.email ?? ''}'),
            ElevatedButton(
              onPressed: changePassword,
              child: const Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () async {
                await auth.signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}