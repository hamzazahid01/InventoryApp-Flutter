// FlutterFire / Firebase options.
//
// If Storage uploads return HTTP 404, open Firebase Console → Project settings
// and set [storageBucket] here to the **exact** "Storage bucket" string shown
// (often `project-id.appspot.com`; sometimes `project-id.firebasestorage.app`).

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
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAtlGFE2qzvV6Z2jb0nbdw2kOGqhpXsDqw',
    appId: '1:148097199115:web:2c62db773c544455286b0e',
    messagingSenderId: '148097199115',
    projectId: 'inventory-app-9092b',
    authDomain: 'inventory-app-9092b.firebaseapp.com',
    storageBucket: 'inventory-app-9092b.appspot.com',
    measurementId: 'G-SGXKQGDRFC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwwhKGf-e-DmGNyz5w8Wuq7npCwl_6qqE',
    appId: '1:148097199115:android:93b47d99e6373e0b286b0e',
    messagingSenderId: '148097199115',
    projectId: 'inventory-app-9092b',
    storageBucket: 'inventory-app-9092b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB8GDr4HFDxwnuJXyCC4Eqe3c2hC8F5Vgw',
    appId: '1:148097199115:ios:8e4088acfb52eaa5286b0e',
    messagingSenderId: '148097199115',
    projectId: 'inventory-app-9092b',
    storageBucket: 'inventory-app-9092b.appspot.com',
    iosBundleId: 'com.example.inventoryManager',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB8GDr4HFDxwnuJXyCC4Eqe3c2hC8F5Vgw',
    appId: '1:148097199115:ios:8e4088acfb52eaa5286b0e',
    messagingSenderId: '148097199115',
    projectId: 'inventory-app-9092b',
    storageBucket: 'inventory-app-9092b.appspot.com',
    iosBundleId: 'com.example.inventoryManager',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAtlGFE2qzvV6Z2jb0nbdw2kOGqhpXsDqw',
    appId: '1:148097199115:web:61c319c3d1e8979b286b0e',
    messagingSenderId: '148097199115',
    projectId: 'inventory-app-9092b',
    authDomain: 'inventory-app-9092b.firebaseapp.com',
    storageBucket: 'inventory-app-9092b.appspot.com',
    measurementId: 'G-RECE5YFWPK',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'REPLACE_LINUX_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'inventory-app-9092b',
    authDomain: 'inventory-app-9092b.firebaseapp.com',
    storageBucket: 'inventory-app-9092b.appspot.com',
  );
}