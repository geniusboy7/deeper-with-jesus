// File generated manually from GoogleService-Info.plist and google-services.json.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.android:
        return _android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyAuaHMXa-6bOf9xBcR4by9pV_4TOOMyqZo',
    appId: '1:173300136692:android:7d8f01d390f232c718bca1',
    messagingSenderId: '173300136692',
    projectId: 'deeper-with-jesus',
    storageBucket: 'deeper-with-jesus.firebasestorage.app',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyCMirGxeAd3g111yfUQKPrg_YvCZG__RzA',
    appId: '1:173300136692:ios:f60cd33b6b452b0018bca1',
    messagingSenderId: '173300136692',
    projectId: 'deeper-with-jesus',
    storageBucket: 'deeper-with-jesus.firebasestorage.app',
    iosClientId: '173300136692-bnsdinc0486dcas1be2hqq9n8rv85fei.apps.googleusercontent.com',
    iosBundleId: 'com.deeperwithjesus.deeperWithJesus',
  );
}
