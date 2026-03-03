// lib/firebase_options.dart
//
// ─────────────────────────────────────────────────────────────────────────────
//  AUTO-GENERATED — replace with your real config from Firebase Console
//  Run: flutterfire configure
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Replace ALL values below with your actual Firebase project config ──

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBF1fGbZZFEMDVeeRYYtdqEoXKkK6mjKj4',
    appId: '1:1062229441862:web:e2decb0786b5ebe058b947',
    messagingSenderId: '1062229441862',
    projectId: 'ecclesia-10b20',
    authDomain: 'ecclesia-10b20.firebaseapp.com',
    storageBucket: 'ecclesia-10b20.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBhV-TlUW5W_dCvQbldpBm12IIGLJrrjUg',
    appId: '1:1062229441862:android:1a4abcd71c759ca158b947',
    messagingSenderId: '1062229441862',
    projectId: 'ecclesia-10b20',
    storageBucket: 'ecclesia-10b20.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    iosBundleId: 'com.yourcompany.ecclesia',
  );
}