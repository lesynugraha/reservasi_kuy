import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:reservation_app/src/data/model/building_model.dart';
import 'package:reservation_app/src/data/model/history_model.dart';
import 'package:reservation_app/src/presentation/utils/general/parsing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/extracurricular_model.dart';
import '../model/reservation_model.dart';
import '../model/user_model.dart';


// Menggunakan part/part of untuk memecah file repository agar lebih modular tapi tetap dalam satu scope library.
part 'authentication_repo.dart';

part 'reservation_repo.dart';

part 'building_repo.dart';

part 'history_repo.dart';

part 'user_repo.dart';

part 'extracurricular_repo.dart';

class Repositories {
  // Instance Firestore utama yang digunakan oleh seluruh repository.
  final db = FirebaseFirestore.instance;

  // Inisialisasi semua repository anak (child repositories) di sini.
  // Ini memudahkan pemanggilan di Bloc, jadi cukup panggil kelas 'Repositories' untuk akses semua fitur database.
  final authentication = AuthenticationRepo();
  final reservation = ReservationRepo();
  final building = BuildingRepo();
  final history = HistoryRepo();
  final user = UserRepo();
  final exschool = ExschoolRepo();
}
