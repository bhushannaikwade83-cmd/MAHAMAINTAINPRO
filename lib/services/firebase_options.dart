import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBgOJ9pSoj9Ey6MiOtxviBY0PAsgUVg_sU',
    appId: '1:326935961034:web:4050c9858ab17563c38333',
    messagingSenderId: '326935961034',
    projectId: 'mahamaintainpro-6440d',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBgOJ9pSoj9Ey6MiOtxviBY0PAsgUVg_sU',
    appId: '1:326935961034:android:4050c9858ab17563c38333',
    messagingSenderId: '326935961034',
    projectId: 'mahamaintainpro-6440d',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgOJ9pSoj9Ey6MiOtxviBY0PAsgUVg_sU',
    appId: '1:326935961034:ios:4050c9858ab17563c38333',
    messagingSenderId: '326935961034',
    projectId: 'mahamaintainpro-6440d',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBgOJ9pSoj9Ey6MiOtxviBY0PAsgUVg_sU',
    appId: '1:326935961034:ios:4050c9858ab17563c38333',
    messagingSenderId: '326935961034',
    projectId: 'mahamaintainpro-6440d',
  );
}
