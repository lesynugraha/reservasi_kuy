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

  /// mendapatkan informasi reservasi berdasarkan user
  getReservationForUser(String contactId) async {
    error = "";
    statusCode = "";

    try {
      QuerySnapshot resultReservations = await Repositories()
          .db
          .collection("reservations")
          .where("contactId", isEqualTo: contactId)
          .get();

      if (resultReservations.docs.isNotEmpty) {
        statusCode = "200";
        final List<ReservationModel> reservations = resultReservations.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();
        final onReservation = reservations
            .where(
              (element) =>
          element.status == "Menunggu" ||
              element.status == "Disetujui" ||
              element.status == "Ditolak",
        )
            .toList();
        return onReservation;
      } else {
        statusCode = "200";
        final List<ReservationModel> reservations = [];
        return reservations;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// membatalkan reservasi
  cancelReservation(String contactId) async {
    error = "";
    statusCode = "";

    try {
      QuerySnapshot resultReservations = await Repositories()
          .db
          .collection("reservations")
          .where("contactId", isEqualTo: contactId)
          .get();

      if (resultReservations.docs.isNotEmpty) {
        statusCode = "200";
        final List<ReservationModel> reservations = resultReservations.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();
        return reservations;
      } else {
        statusCode = "200";
        final List<ReservationModel> reservations = [];
        return reservations;
      }
    } catch (e) {
      throw Exception(e);
    }
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

  // vvv INI BAGIAN PENTING YANG SERING TERLEWAT vvv
  /// menyetujui atau menolak reservasi (update status dan note)
  updateStatusReservation(String id, String status, {String? note}) async {
    statusCode = "";
    try {
      // Siapkan data update
      Map<String, dynamic> dataToUpdate = {
        "status": status,
      };

      // Cek apakah ada note, jika ada masukkan ke data update
      if (note != null && note.isNotEmpty) {
        dataToUpdate["note"] = note;
      }

      // Update ke Firestore
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
  // ^^^ SAMPAI SINI ^^^

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
            // Parsing tanggal hanya sekali untuk efisiensi
            final DateTime elementStart = DateTime.parse(element.dateStart!);
            final DateTime elementEnd = DateTime.parse(element.dateEnd!);
            final DateTime enteredStart = DateTime.parse(dateStart);
            final DateTime enteredEnd = DateTime.parse(dateEnd);

            // Cek apakah interval bersinggungan
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

  /// mendapatkan informasi reservasi bagi admin (berdasarkan instansi)
  getReservationForAdmin(String agency) async {
    error = "";
    statusCode = "";

    try {
      QuerySnapshot resultReservations = await Repositories()
          .db
          .collection("reservations")
          .where("agency", isEqualTo: agency)
          .get();

      if (resultReservations.docs.isNotEmpty) {
        statusCode = "200";
        final List<ReservationModel> reservations = resultReservations.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();
        final onReservation = reservations
            .where(
              (element) =>
          element.status == "Menunggu" || element.status == "Disetujui",
        )
            .toList();
        return onReservation;
      } else {
        statusCode = "200";
        final List<ReservationModel> reservations = [];
        return reservations;
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
