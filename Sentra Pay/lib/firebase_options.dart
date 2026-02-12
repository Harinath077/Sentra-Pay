import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCfEt2ZRXMnDHsZqes7Qmq5hXiPSIGs9S0',
    appId: '1:62983503020:web:20d18e3d0ef7bdc53b3309',
    messagingSenderId: '62983503020',
    projectId: 'sentra-pay-4eb02',
    authDomain: 'sentra-pay-4eb02.firebaseapp.com',
    storageBucket: 'sentra-pay-4eb02.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCfEt2ZRXMnDHsZqes7Qmq5hXiPSIGs9S0',
    appId: '1:62983503020:android:5fe63bc94aa36cd23b3309',
    messagingSenderId: '62983503020',
    projectId: 'sentra-pay-4eb02',
    storageBucket: 'sentra-pay-4eb02.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCfEt2ZRXMnDHsZqes7Qmq5hXiPSIGs9S0',
    appId: '1:62983503020:ios:YOUR_IOS_APP_ID', // Get from Firebase Console iOS app
    messagingSenderId: '62983503020',
    projectId: 'sentra-pay-4eb02',
    storageBucket: 'sentra-pay-4eb02.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.sentra.upiRiskApp',
  );
}
