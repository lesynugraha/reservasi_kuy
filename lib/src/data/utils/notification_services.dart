// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class NotificationServices {
//   final _firebaseMessaging = FirebaseMessaging.instance;
//
//   initialMessaging() async {
//     try {
//       await _firebaseMessaging.requestPermission();
//       await _firebaseMessaging.getToken();
//     } catch (e) {
//       throw Exception(e);
//     }
//   }
// }

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationServices {
  final _firebaseMessaging = FirebaseMessaging.instance;

  initialMessaging() async {
    try {
      await _firebaseMessaging.requestPermission();
      // await _firebaseMessaging.getToken(); //tidak panggil otomatis di sini
    } catch (e) {
      throw Exception(e);
    }
  }

  // vvv FUNGSI BARU YANG DITAMBAHKAN DI SINI vvv
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        // ditambahkan "=====" agar mudah dicari di log/terminal
        print("===== FCM Token: $token =====");
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print("Error getting FCM token: $e");
      }
      return null;
    }
  }
}
