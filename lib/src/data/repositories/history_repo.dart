part of 'repositories.dart';

/// Repository ini menangani akses data untuk dua koleksi sekaligus:
/// 1. 'histories': Data riwayat yang dilihat dari sisi User (Siswa).
/// 2. 'reports': Data laporan yang dilihat dari sisi Admin (Sekolah).
class HistoryRepo {
  late String error;
  late String statusCode;

  /// user: mendapatkan informasi riwayat reservasi
  /// Mengambil data dari collection 'histories' dengan filter 'contactId'.
  /// Logic ini memastikan User hanya bisa melihat riwayat miliknya sendiri (Data Privacy).
  getHistory(String contactId) async {
    error = "";
    statusCode = "";

    try {
      QuerySnapshot resultHistories = await Repositories()
          .db
          .collection("histories")
          .where("contactId", isEqualTo: contactId) // Filter data server-side
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
  /// Fungsi ini dijalankan saat reservasi selesai atau disetujui, mencatat jejak aktivitas.
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
        String? note,
        String? proofImage, // <--- [BARU] Terima Proof Image
      }) async {
    error = "";
    statusCode = "";

    try {
      // 1. Tambahkan dokumen baru ke Firestore (Auto-Generated ID)
      await Repositories().db.collection("histories").add({
        "id": "", // ID sementara kosong
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
        "note": note ?? "",
        "proofImage": proofImage ?? "", // <--- [BARU] Simpan URL bukti bayar
      }).then(
            (value) {
          // 2. Update dokumen tersebut untuk menyimpan ID-nya sendiri
          // Ini memudahkan referensi update/delete di masa depan
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
  /// Mengubah status laporan menjadi selesai dengan mengisi timestamp 'dateFinished'.
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
  /// Berbeda dengan getHistory, fungsi ini memfilter berdasarkan 'agency'.
  /// Memungkinkan Admin melihat rekap semua kegiatan siswa di sekolah tersebut.
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
  /// Menggunakan metode .set() bukan .add() karena kita ingin menentukan ID dokumen secara manual.
  /// Biasanya digunakan saat memindahkan data dari 'Reservasi' ke 'Report' agar ID-nya tetap konsisten.
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
        String? note,
        String? proofImage, // <--- [BARU] Terima Proof Image
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
        "note": note ?? "",
        "proofImage": proofImage ?? "", // <--- [BARU] Simpan ke Firestore
      });
      statusCode = "200";
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Membuat laporan manual (Input Admin).
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
        String? note,
        String? proofImage, // <--- [BARU] Terima Proof Image
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
        "note": note ?? "",
        "proofImage": proofImage ?? "", // <--- [BARU] Simpan ke Firestore
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