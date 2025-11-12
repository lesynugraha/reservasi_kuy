part of 'repositories.dart';

class HistoryRepo {
  late String error;
  late String statusCode;

  /// user: mendapatkan informasi riwayat reservasi
  getHistory(String contactId) async {
    error = "";
    statusCode = "";

    try {
      QuerySnapshot resultHistories = await Repositories()
          .db
          .collection("histories") // pastikan nama koleksi benar
          .where("contactId", isEqualTo: contactId)
          .get();

      if (resultHistories.docs.isNotEmpty) {
        statusCode = "200";
        final List<HistoryModel> histories =
        resultHistories.docs.map((e) => HistoryModel.fromJson(e)).toList();
        return histories;
      } else {
        statusCode = "200";
        final List<HistoryModel> histories = [];
        return histories;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// user: membuat riwayat reservasi
  createHistory(
      String buildingName,
      String dateStart,
      String dateEnd,
      String dateCreated,
      String dateFinished,
      String contactId,
      String contactName,
      String information,
      String status,
      String agency,
      String image, {
        String? note, // <--- DITAMBAHKAN
      }) async {
    error = "";
    statusCode = "";

    try {
      await Repositories().db.collection("histories").add({
        "id": "",
        "buildingName": buildingName,
        "dateStart": dateStart,
        "dateEnd": dateEnd,
        "dateCreated": dateCreated,
        "dateFinished": dateFinished,
        "contactId": contactId,
        "contactName": contactName,
        "information": information,
        "status": status,
        "agency": agency,
        "image": image,
        "note": note ?? "", // <--- DISIMPAN
      }).then(
            (value) {
          Repositories()
              .db
              .collection("histories")
              .doc(value.id)
              .update({"id": value.id});
        },
      );
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  /// user: update laporan diselesaikan
  updateFinishedReport(String id) async {
    statusCode = "";
    try {
      await Repositories()
          .db
          .collection("reports")
          .doc(id)
          .update({"dateFinished": DateTime.now().toString()});
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: mendapatkan informasi laporan
  getReportByAgency(String agency) async {
    statusCode = "";
    try {
      QuerySnapshot resultHistory = await Repositories()
          .db
          .collection("reports")
          .where("agency", isEqualTo: agency)
          .get();
      if (resultHistory.docs.isNotEmpty) {
        statusCode = "200";
        final List<HistoryModel> reports =
        resultHistory.docs.map((e) => HistoryModel.fromJson(e)).toList();
        return reports;
      } else {
        statusCode = "200";
        final List<HistoryModel> reports = [];
        return reports;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: membuat laporan reservasi (custom id)
  createReportCustomId(
      String id,
      String buildingName,
      String dateStart,
      String dateEnd,
      String dateCreated,
      String contactId,
      String contactName,
      String information,
      String status,
      String agency,
      String image, {
        String? note, // <--- DITAMBAHKAN
      }) async {
    statusCode = "";

    try {
      await Repositories().db.collection("reports").doc(id).set({
        "id": id,
        "buildingName": buildingName,
        "dateStart": dateStart,
        "dateEnd": dateEnd,
        "dateCreated": dateCreated,
        "dateFinished": status == "Ditolak" ? DateTime.now().toString() : "",
        "contactId": contactId,
        "contactName": contactName,
        "information": information,
        "status": status,
        "agency": agency,
        "image": image,
        "note": note ?? "", // <--- DISIMPAN
      });
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  createReport(
      String buildingName,
      String dateStart,
      String dateEnd,
      String dateCreated,
      String contactId,
      String contactName,
      String information,
      String status,
      String agency,
      String image, {
        String? note, // <--- DITAMBAHKAN
      }) async {
    error = "";
    statusCode = "";

    try {
      await Repositories().db.collection("reports").add({
        "id": "",
        "buildingName": buildingName,
        "dateStart": dateStart,
        "dateEnd": dateEnd,
        "dateCreated": dateCreated,
        "dateFinished": "",
        "contactId": contactId,
        "contactName": contactName,
        "information": information,
        "status": status,
        "agency": agency,
        "image": image,
        "note": note ?? "", // <--- DISIMPAN
      }).then(
            (value) {
          Repositories()
              .db
              .collection("reports")
              .doc(value.id)
              .update({"id": value.id});
        },
      );
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }
}