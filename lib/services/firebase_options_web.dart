import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummy1234567890',
    appId: '1:123456789:web:abcdef1234567890',
    messagingSenderId: '123456789',
    projectId: 'dummy-project',
    authDomain: 'dummy-project.firebaseapp.com',
    databaseURL: 'https://dummy-project.firebaseio.com',
    storageBucket: 'dummy-project.appspot.com',
    measurementId: 'G-DUMMY1234',
  );

  static FirebaseOptions get currentPlatform {
    return web;
  }
}
