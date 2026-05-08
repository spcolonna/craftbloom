import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no soporta esta plataforma: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCizkR_DI9xW6dXDh--oC5J-hNvGK8GGko',
    authDomain: 'craftbloom-1fde1.firebaseapp.com',
    projectId: 'craftbloom-1fde1',
    storageBucket: 'craftbloom-1fde1.firebasestorage.app',
    messagingSenderId: '1003770226717',
    appId: '1:1003770226717:web:8e2d530b0f17180a287ef4',
    measurementId: 'G-WDWFX3XFKR',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAC2oE6VpbpW_x41DssCWbHkadLEQyunJU',
    appId: '1:1003770226717:ios:bbd19d4a6e612e90287ef4',
    messagingSenderId: '1003770226717',
    projectId: 'craftbloom-1fde1',
    storageBucket: 'craftbloom-1fde1.firebasestorage.app',
    iosClientId: '1003770226717-acod1gh111a8cc89dntuhr7qlj5ln88p.apps.googleusercontent.com',
    iosBundleId: 'com.craftbloom.craftbloom',
  );
}
