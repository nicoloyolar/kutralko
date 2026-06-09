import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlOCoVmGSNmYio_S9UeAc1F55bDJv4T14',
    appId: '1:210492772705:android:e5f51231d4632cdf73b520',
    messagingSenderId: '210492772705',
    projectId: 'kutralko-2e192',
    authDomain: 'kutralko-2e192.firebaseapp.com',
    storageBucket: 'kutralko-2e192.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlOCoVmGSNmYio_S9UeAc1F55bDJv4T14',
    appId: '1:210492772705:android:e5f51231d4632cdf73b520',
    messagingSenderId: '210492772705',
    projectId: 'kutralko-2e192',
    storageBucket: 'kutralko-2e192.firebasestorage.app',
  );
}
