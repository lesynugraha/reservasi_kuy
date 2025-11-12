part of 'repositories.dart';

class UserRepo {
  late String statusCode;
  late String error;

  /// get single user by username
  getUser(String username) async {
    statusCode = "";
    try {
      QuerySnapshot resultUser = await Repositories()
          .db
          .collection("users")
          .where("username", isEqualTo: username)
          .get();
      if (resultUser.docs.isNotEmpty) {
        statusCode = "200";
        final user = resultUser.docs.first;
        final userModel = UserModel.fromJson(user.data());
        return userModel;
      } else {
        statusCode = "200";
        return;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Menyimpan FCM Token ke dokumen user
  Future<void> updateUserFCMToken(String username, String token) async {
    try {
      // 1. Cari dokumen user berdasarkan 'username'
      QuerySnapshot querySnapshot = await Repositories()
          .db
          .collection("users")
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 2. Jika user ditemukan, dapatkan ID dokumennya
        String docId = querySnapshot.docs.first.id;

        // 3. Update dokumen tersebut dengan fcmToken baru
        await Repositories().db.collection("users").doc(docId).update({
          // field yang akan dibaca oleh Cloud Function
          'fcmToken': token,
        });
        if (kDebugMode) {
          print("FCM Token berhasil disimpan untuk $username");
        }
      } else {
        if (kDebugMode) {
          print("User $username tidak ditemukan untuk update token.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error saat update FCM token: $e");
      }
    }
  }

  /// tambah user
  register(
    String agency,
    String username,
    String password,
    String fullName,
    String role,
  ) async {
    statusCode = "";
    error = "";
    final parsedAgency = ParsingString().removeMultiSpace(agency);
    try {
      /// check if user already exist
      QuerySnapshot resultUser = await Repositories()
          .db
          .collection("users")
          .where("username", isEqualTo: username.toLowerCase())
          .get();
      if (resultUser.docs.isNotEmpty) {
        /// username is exist
        error = "Username sudah digunakan";
      } else {
        /// check if agency already exist
        QuerySnapshot resultAgency = await Repositories()
            .db
            .collection("users")
            .where("agency", isEqualTo: parsedAgency.toLowerCase())
            .where("role", isEqualTo: "1")
            .get();

        if (resultAgency.docs.isNotEmpty) {
          /// agency is exist
          error = "Instasi sudah ada, coba yang lain";
        } else {
          /// add user
          await Repositories().db.collection("users").add({
            "id": "",
            "agency": parsedAgency,
            "username": username.toLowerCase(),
            "password": password,
            "fullName": fullName,
            "email": "",
            "phone": "",
            "image": "",
            "role": role,
          }).then(
            (value) {
              Repositories()
                  .db
                  .collection("users")
                  .doc(value.id)
                  .update({"id": value.id});
            },
          );
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///admin: Get user berdasarkan instansi
  getAllUserByAgency(String agency) async {
    statusCode = "";
    try {
      QuerySnapshot resultUser = await Repositories()
          .db
          .collection("users")
          .where("agency", isEqualTo: agency)
          .where("role", isEqualTo: "2")
          .get();
      if (resultUser.docs.isNotEmpty) {
        statusCode = "200";
        final List<UserModel> users =
            resultUser.docs.map((e) => UserModel.fromJson(e)).toList();

        return users;
      } else {
        statusCode = "200";
        final List<UserModel> users = [];
        return users;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///super admin: get all user
  getAllUserSuperAdmin() async {
    statusCode = "";
    try {
      QuerySnapshot resultUser = await Repositories()
          .db
          .collection("users")
          .where("role", isEqualTo: "1")
          .get();
      if (resultUser.docs.isNotEmpty) {
        statusCode = "200";
        final List<UserModel> users =
            resultUser.docs.map((e) => UserModel.fromJson(e)).toList();
        return users;
      } else {
        statusCode = "200";
        final List<UserModel> users = [];
        return users;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///delete user
  deleteUser(String id) async {
    statusCode = "";
    try {
      await Repositories().db.collection("users").doc(id).delete();
      statusCode = "200";
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  ///delete user
  deleteUserSuperAdmin(String agency) async {
    statusCode = "";
    WriteBatch batch = Repositories().db.batch();
    try {
      // user
      final responseListUser = await Repositories()
          .db
          .collection("users")
          .where("agency", isEqualTo: agency)
          .get();
      final List<UserModel> listUser = responseListUser.docs
          .map(
            (e) => UserModel.fromJson(e),
          )
          .toList();
      for (var user in listUser) {
        DocumentReference docRef =
            Repositories().db.collection("users").doc(user.id);
        batch.delete(docRef);
      }

      // building
      final responseListBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("agency", isEqualTo: agency)
          .get();
      final List<BuildingModel> listBuilding = responseListBuilding.docs
          .map(
            (e) => BuildingModel.fromJson(e),
          )
          .toList();
      for (var building in listBuilding) {
        DocumentReference docRef =
            Repositories().db.collection("buildings").doc(building.id);
        batch.delete(docRef);
      }

      // extracurriculars
      final responseListExcur = await Repositories()
          .db
          .collection("extracurriculars")
          .where("agency", isEqualTo: agency)
          .get();
      final List<ExtracurricularModel> listExcur = responseListExcur.docs
          .map(
            (e) => ExtracurricularModel.fromJson(e),
          )
          .toList();
      for (var excur in listExcur) {
        DocumentReference docRef =
            Repositories().db.collection("extracurriculars").doc(excur.id);
        batch.delete(docRef);
      }

      // histories
      final responseListHistory = await Repositories()
          .db
          .collection("histories")
          .where("agency", isEqualTo: agency)
          .get();
      final List<HistoryModel> listHistory = responseListHistory.docs
          .map(
            (e) => HistoryModel.fromJson(e),
          )
          .toList();
      for (var history in listHistory) {
        DocumentReference docRef =
            Repositories().db.collection("histories").doc(history.id);
        batch.delete(docRef);
      }

      // reservations
      final responseListReservation = await Repositories()
          .db
          .collection("reservations")
          .where("agency", isEqualTo: agency)
          .get();
      final List<ReservationModel> listReservation =
          responseListReservation.docs
              .map(
                (e) => ReservationModel.fromJson(e),
              )
              .toList();
      for (var reservation in listReservation) {
        DocumentReference docRef =
            Repositories().db.collection("reservations").doc(reservation.id);
        batch.delete(docRef);
      }

      // reports
      final responseListReport = await Repositories()
          .db
          .collection("reports")
          .where("agency", isEqualTo: agency)
          .get();
      final List<HistoryModel> listReport = responseListReport.docs
          .map(
            (e) => HistoryModel.fromJson(e),
          )
          .toList();
      for (var report in listReport) {
        DocumentReference docRef =
            Repositories().db.collection("reports").doc(report.id);
        batch.delete(docRef);
      }

      // execute
      await batch.commit();
      statusCode = "200";
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  ///edit/update user
  editUser(
    String id,
    String agency,
    String username,
    String password,
    String fullName,
    String email,
    String phone,
  ) async {
    statusCode = "";
    try {
      await Repositories().db.collection("users").doc(id).update({
        "agency": agency,
        "username": username,
        "password": password,
        "fullName": fullName,
        "email": email,
        "phone": phone,
      });
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  ///edit profile picture
  editProfilePicture(
    String id,
    String image,
  ) async {
    statusCode = "";
    try {
      await Repositories().db.collection("users").doc(id).update({
        "image": image,
      });
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  ///edit password
  editPassword(
    String id,
    String username,
    String oldPassword,
    String newPassword,
  ) async {
    statusCode = "";
    error = "";
    try {
      QuerySnapshot resultUser = await Repositories()
          .db
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (resultUser.docs.isNotEmpty) {
        final doc = resultUser.docs.first;
        if (doc["password"] == oldPassword) {
          await Repositories().db.collection("users").doc(id).update({
            "password": newPassword,
          });
        } else {
          error = "Kata sandi lama anda salah!";
        }
      } else {
        error = "Pengguna tidak ditemukan!";
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// change username only
  changeUsername(
    String id,
    String username,
  ) async {
    error = "";

    /// check if user already exist
    QuerySnapshot resultUser = await Repositories()
        .db
        .collection("users")
        .where("username", isEqualTo: username.toLowerCase())
        .get();
    if (resultUser.docs.isNotEmpty) {
      /// username is exist
      error = "Nama pengguna sudah digunakan";
    } else {
      await Repositories().db.collection("users").doc(id).update({
        "username": username,
      });
    }

    /// add user
  }
}
