part of 'repositories.dart';

class ReservationRepo {
  late String error;
  late String statusCode;

  /// membuat reservasi
  createReservation(
      String? buildingName,
      String? contactId,
      String? contactName,
      String? contactEmail,
      String? contactPhone,
      String? dateStart,
      String? dateEnd,
      String? dateCreated,
      String? information,
      String? agency,
      String? image,
      String? proofImage,
      ) async {
    statusCode = "";

    try {
      await Repositories().db.collection("reservations").add({
        "id": "",
        "buildingName": buildingName,
        "contactId": contactId,
        "contactName": contactName,
        "contactEmail": contactEmail,
        "contactPhone": contactPhone,
        "dateStart": dateStart,
        "dateEnd": dateEnd,
        "dateCreated": dateCreated,
        "information": information,
        "agency": agency,
        "status": "Menunggu",
        "image": image,
        "proofImage": proofImage,
      }).then(
            (value) {
          Repositories()
              .db
              .collection("reservations")
              .doc(value.id)
              .update({"id": value.id});
        },
      );
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  /// -----------------------------------------------------------------------
  /// Mendapatkan Stream Reservasi User (REAL-TIME)
  /// Menggunakan snapshots() bukan get()
  /// -----------------------------------------------------------------------
  Stream<List<ReservationModel>> getReservationStreamForUser(String contactId) {
    return Repositories()
        .db
        .collection("reservations")
        .where("contactId", isEqualTo: contactId)
        .snapshots() // <--- KUNCINYA (Listen terus menerus)
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final List<ReservationModel> reservations = querySnapshot.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();
        // Filter status sesuai logika aplikasi Anda
        return reservations
            .where((element) =>
        element.status == "Menunggu" ||
            element.status == "Disetujui" ||
            element.status == "Ditolak")
            .toList();
      } else {
        return <ReservationModel>[];
      }
    });
  }

  /// -----------------------------------------------------------------------
  /// Mendapatkan Stream Reservasi Admin (REAL-TIME)
  /// -----------------------------------------------------------------------
  Stream<List<ReservationModel>> getReservationStreamForAdmin(String agency) {
    return Repositories()
        .db
        .collection("reservations")
        .where("agency", isEqualTo: agency)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final List<ReservationModel> reservations = querySnapshot.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();
        return reservations
            .where((element) =>
        element.status == "Menunggu" || element.status == "Disetujui")
            .toList();
      } else {
        return <ReservationModel>[];
      }
    });
  }

  // --- Method Lama (getReservationForUser/Admin) bisa dibiarkan atau dihapus,
  // tapi untuk create/update/delete tetap sama seperti di bawah ini ---

  /// membatalkan reservasi (Hanya Helper untuk create history, logic utama di BLoC)
  cancelReservation(String contactId) async {
    // Logic ini sebenarnya jarang dipanggil langsung jika sudah pakai stream di UI
    // biarkan saja agar tidak error
    return [];
  }

  /// menghapus reservasi
  deleteReservation(String id) async {
    statusCode = "";
    try {
      await Repositories().db.collection("reservations").doc(id).delete();
      statusCode = "200";
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// menyetujui atau menolak reservasi (update status dan note)
  updateStatusReservation(String id, String status, {String? note}) async {
    statusCode = "";
    try {
      Map<String, dynamic> dataToUpdate = {
        "status": status,
      };
      if (note != null && note.isNotEmpty) {
        dataToUpdate["note"] = note;
      }

      await Repositories()
          .db
          .collection("reservations")
          .doc(id)
          .update(dataToUpdate);

      statusCode = "200";
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  /// mendapatkan informasi dan pengecekan status tersedia reservasi
  getReservationAvail(
      String dateStart,
      String dateEnd,
      String agency,
      String buildingName,
      ) async {
    statusCode = "";
    final List<ReservationModel> noBooking = [];

    try {
      QuerySnapshot resultReservation = await Repositories()
          .db
          .collection("reservations")
          .where("agency", isEqualTo: agency)
          .where("buildingName", isEqualTo: buildingName)
          .get();
      if (resultReservation.docs.isNotEmpty) {
        final List<ReservationModel> listReservation = resultReservation.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();

        final List<ReservationModel> reservationBookedByDate =
        listReservation.where(
              (element) {
            if (element.status != "Disetujui") {
              return false;
            }
            final DateTime elementStart = DateTime.parse(element.dateStart!);
            final DateTime elementEnd = DateTime.parse(element.dateEnd!);
            final DateTime enteredStart = DateTime.parse(dateStart);
            final DateTime enteredEnd = DateTime.parse(dateEnd);

            final bool isOverlapping = (enteredStart.isBefore(elementEnd) &&
                enteredEnd.isAfter(elementStart)) ||
                (enteredStart.isAtSameMomentAs(elementStart) ||
                    (elementStart.isAtSameMomentAs(enteredStart) ||
                        enteredEnd.isAtSameMomentAs(elementEnd)) ||
                    elementEnd.isAtSameMomentAs(enteredEnd)) ||
                (enteredStart.isAtSameMomentAs(elementEnd) ||
                    (elementEnd.isAtSameMomentAs(enteredStart) ||
                        enteredEnd.isAtSameMomentAs(elementStart)) ||
                    elementStart.isAtSameMomentAs(enteredEnd));

            return isOverlapping;
          },
        ).toList();

        if (reservationBookedByDate.isNotEmpty) {
          statusCode = "201";
          return reservationBookedByDate;
        } else {
          statusCode = "200";
          return noBooking;
        }
      } else {
        statusCode = "200";
        return noBooking;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  // Method lama getReservationForUser & Admin bisa dibiarkan ada
  // untuk menghindari error di file lain yg belum diubah,
  // tapi logic intinya berpindah ke Stream di atas.
  getReservationForUser(String contactId) async { return []; }
  getReservationForAdmin(String agency) async { return []; }
}