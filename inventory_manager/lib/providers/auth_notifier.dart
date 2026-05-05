import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  // Default bootstrap admin credentials (change later in Firebase Console).
  static const defaultAdminEmail = 'admin@inventory.local';
  static const defaultAdminPassword = 'Admin@12345';

  final FirebaseAuth _auth;

  StreamSubscription<User?>? _sub;

  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isSignedIn => _user != null;
  /// Simple policy: any signed-in user is an admin.
  bool get isAdmin => isSignedIn;

  Future<void> load() async {
    _sub ??= _auth.authStateChanges().listen((u) async {
      _user = u;
      _loading = true;
      notifyListeners();

      if (u == null) {
        _loading = false;
        notifyListeners();
        return;
      }

      _loading = false;
      notifyListeners();
    });
  }

  Future<void> disposeAsync() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    unawaited(disposeAsync());
    super.dispose();
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> ensureBootstrapAdminExists() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: defaultAdminEmail,
        password: defaultAdminPassword,
      );
    } on FirebaseAuthException catch (e) {
      // If it already exists, ignore.
      if (e.code == 'email-already-in-use') return;
      // If Email/Password sign-in is disabled, ignore (guest mode still works).
      if (e.code == 'operation-not-allowed') return;
      rethrow;
    }
  }
}

