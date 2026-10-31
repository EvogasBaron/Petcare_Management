import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Cấu hình Firebase cho dự án petcare-5396b
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCT9jonefglzJwybYSj8uyugQqIziwO8A',
    appId: '1:236136088666:android:47faf5699b25a3dd60c463',
    messagingSenderId: '236136088666',
    projectId: 'petcare-5396b',
    storageBucket: 'petcare-5396b.firebasestorage.app',
  );
}
