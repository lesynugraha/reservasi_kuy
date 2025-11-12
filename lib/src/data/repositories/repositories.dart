import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:reservation_app/src/data/model/building_model.dart';
import 'package:reservation_app/src/data/model/history_model.dart';
import 'package:reservation_app/src/presentation/utils/general/parsing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/extracurricular_model.dart';
import '../model/reservation_model.dart';
import '../model/user_model.dart';

part 'authentication_repo.dart';

part 'reservation_repo.dart';

part 'building_repo.dart';

part 'history_repo.dart';

part 'user_repo.dart';

part 'extracurricular_repo.dart';

class Repositories {
  final db = FirebaseFirestore.instance;
  final authentication = AuthenticationRepo();
  final reservation = ReservationRepo();
  final building = BuildingRepo();
  final history = HistoryRepo();
  final user = UserRepo();
  final exschool = ExschoolRepo();
}
