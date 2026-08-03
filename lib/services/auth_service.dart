import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'db_service.dart';
import 'sync_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  // Initialize GoogleSignIn. For iOS, we can optionally pass the clientId if not using GoogleService-Info.plist.
  // But flutterfire configure usually sets up the plist.
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint("Anonymous Sign-In Error: $e");
      return null;
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      if (googleAuth == null) return null;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Push any local (guest) scans to Firestore
      await SyncService.syncLocalToCloud();
      
      // Sync cloud data to local Isar after successful sign-in
      await SyncService.syncFromCloudToLocal();
      
      // Start real-time sync listener to keep phones synced
      SyncService.startRealtimeSync();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  static Future<User?> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      await SyncService.syncLocalToCloud();
      await SyncService.syncFromCloudToLocal();
      SyncService.startRealtimeSync();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      return null;
    }
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      await SyncService.syncLocalToCloud();
      await SyncService.syncFromCloudToLocal();
      SyncService.startRealtimeSync();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      rethrow;
    }
  }

  static Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      await SyncService.syncLocalToCloud();
      await SyncService.syncFromCloudToLocal();
      SyncService.startRealtimeSync();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      rethrow;
    }
  }

  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution (mostly Android)
        await _auth.signInWithCredential(credential);
        await SyncService.syncLocalToCloud();
        await SyncService.syncFromCloudToLocal();
        SyncService.startRealtimeSync();
      },
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<User?> verifyOTP(String verificationId, String smsCode) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      await SyncService.syncLocalToCloud();
      await SyncService.syncFromCloudToLocal();
      SyncService.startRealtimeSync();
      
      return userCredential.user;
    } catch (e) {
      debugPrint("OTP Verification Error: $e");
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      SyncService.stopRealtimeSync();
      await _googleSignIn.signOut();
      await _auth.signOut();
      // Wipe all local database items as requested in the plan
      await DBService.clearAll();
    } catch (e) {
      debugPrint("Sign-Out Error: $e");
    }
  }
}
