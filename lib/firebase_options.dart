// File generated for multiplatform Firebase initialization.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyChX6Jaa9OvWY2kx2iZLAnwBlZg13Bdv7A',
    appId: '1:701658649817:android:1c844e8830856fb910dac8',
    messagingSenderId: '701658649817',
    projectId: 'project-7572829437589541430',
    storageBucket: 'project-7572829437589541430.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyChX6Jaa9OvWY2kx2iZLAnwBlZg13Bdv7A',
    appId: '1:701658649817:ios:1c844e8830856fb910dac8',
    messagingSenderId: '701658649817',
    projectId: 'project-7572829437589541430',
    storageBucket: 'project-7572829437589541430.firebasestorage.app',
    iosBundleId: 'com.ung.dung.nghe.nhac.online',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyChX6Jaa9OvWY2kx2iZLAnwBlZg13Bdv7A',
    appId: '1:701658649817:web:1c844e8830856fb910dac8',
    messagingSenderId: '701658649817',
    projectId: 'project-7572829437589541430',
    storageBucket: 'project-7572829437589541430.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyChX6Jaa9OvWY2kx2iZLAnwBlZg13Bdv7A',
    appId: '1:701658649817:ios:1c844e8830856fb910dac8',
    messagingSenderId: '701658649817',
    projectId: 'project-7572829437589541430',
    storageBucket: 'project-7572829437589541430.firebasestorage.app',
    iosBundleId: 'com.ung.dung.nghe.nhac.online',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyChX6Jaa9OvWY2kx2iZLAnwBlZg13Bdv7A',
    appId: '1:701658649817:android:1c844e8830856fb910dac8',
    messagingSenderId: '701658649817',
    projectId: 'project-7572829437589541430',
    storageBucket: 'project-7572829437589541430.firebasestorage.app',
  );
}
