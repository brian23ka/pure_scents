import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCs5hQpElXYR7AjdgEPu77p5g16_3C5RW0',
    appId: '1:720771771404:web:292c7968af526f7bc29229',
    messagingSenderId: '720771771404',
    projectId: 'purescents-fcbe7',
    authDomain: 'purescents-fcbe7.firebaseapp.com',
    storageBucket: 'purescents-fcbe7.firebasestorage.app',
    measurementId: 'G-34N4F3RKVB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBiXHQO-7OzgrQpOIkpSxSA3uWx1fab3L8',
    appId: '1:720771771404:android:d76c5acc6aa0f458c29229',
    messagingSenderId: '720771771404',
    projectId: 'purescents-fcbe7',
    storageBucket: 'purescents-fcbe7.firebasestorage.app',
  );
}
