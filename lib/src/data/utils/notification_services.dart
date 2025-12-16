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
  // Menggunakan instance Singleton dari FirebaseMessaging.
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Fungsi inisialisasi awal untuk meminta izin notifikasi (penting untuk Android 13+).
  initialMessaging() async {
    try {
      await _firebaseMessaging.requestPermission();
      // Token tidak diambil otomatis di sini untuk menghemat resource, diambil saat dibutuhkan saja.
    } catch (e) {
      throw Exception(e);
    }
  }

  // Fungsi untuk mendapatkan Device Token (FCM Token).
  // Token ini unik untuk setiap perangkat dan digunakan backend untuk mengirim notifikasi ke user spesifik.
  Future<String?> getDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        // Print token di mode debug untuk keperluan testing via Firebase Console.
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