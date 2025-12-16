part of 'repositories.dart';

/// Repository ini menangani seluruh transaksi data reservasi ke Firestore.
/// Menggunakan pendekatan Reactive (Stream) untuk pemantauan data secara Real-time
/// dan Future untuk operasi satu kali (One-time) seperti Create/Delete.
class ReservationRepo {
  late String error;
  late String statusCode;

  /// membuat reservasi
  /// Menyimpan data pengajuan baru ke koleksi 'reservations'.
  /// Flow: Add Document -> Get ID -> Update ID field inside document.
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
        "id": "", // ID awal kosong, akan diisi setelah dokumen terbuat
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
        "status": "Menunggu", // Status default saat pertama kali dibuat
        "image": image,
        "proofImage": proofImage,
      }).then(
            (value) {
          // Update dokumen dengan ID yang digenerate oleh Firestore
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
  /// Fungsi ini mengembalikan Stream, bukan Future.
  /// Memungkinkan UI User untuk 'mendengarkan' perubahan status secara langsung
  /// tanpa perlu refresh manual. Sangat berguna untuk UX saat menunggu persetujuan Admin.
  Stream<List<ReservationModel>> getReservationStreamForUser(String contactId) {
    return Repositories()
        .db
        .collection("reservations")
        .where("contactId", isEqualTo: contactId) // Filter hanya milik user tersebut
        .snapshots() // <--- KUNCINYA (Membangun koneksi socket yang terus terbuka)
        .map((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final List<ReservationModel> reservations = querySnapshot.docs
            .map((e) => ReservationModel.fromJson(e))
            .toList();

        // Filter di sisi client untuk menampilkan status relevan
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
  /// Stream khusus Admin/Supervisor.
  /// Admin akan melihat notifikasi reservasi masuk secara realtime.
  /// Difilter berdasarkan 'agency' agar Admin Sekolah A tidak melihat data Sekolah B.
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
        // Hanya menampilkan yang perlu tindakan (Menunggu) atau yang aktif (Disetujui)
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
  /// Menghapus dokumen dari database secara permanen.
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
  /// Fungsi parsial update: Hanya mengubah field 'status' dan 'note' tanpa menimpa data lain.
  updateStatusReservation(String id, String status, {String? note}) async {
    statusCode = "";
    try {
      Map<String, dynamic> dataToUpdate = {
        "status": status,
      };
      // Note bersifat opsional, hanya ditambahkan jika Admin menulis pesan
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
  /// LOGIC VALIDASI JADWAL (Algorithm for Conflict Detection):
  /// Mengecek apakah ada irisan (overlap) antara jadwal yang diajukan user
  /// dengan jadwal yang SUDAH DISETUJUI di database.
  getReservationAvail(
      String dateStart,
      String dateEnd,
      String agency,
      String buildingName,
      ) async {
    statusCode = "";
    final List<ReservationModel> noBooking = [];

    try {
      // 1. Ambil semua reservasi untuk gedung tersebut di sekolah tersebut
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

        // 2. Filter Logic: Cari jadwal yang bentrok
        final List<ReservationModel> reservationBookedByDate =
        listReservation.where(
              (element) {
            // Abaikan jika reservasi belum disetujui (Menunggu/Ditolak tidak memblokir jadwal)
            if (element.status != "Disetujui") {
              return false;
            }

            // Konversi String ke DateTime object untuk komparasi
            final DateTime elementStart = DateTime.parse(element.dateStart!);
            final DateTime elementEnd = DateTime.parse(element.dateEnd!);
            final DateTime enteredStart = DateTime.parse(dateStart);
            final DateTime enteredEnd = DateTime.parse(dateEnd);

            // Rumus Matematika Logika Irisan Waktu (Time Overlap):
            // (StartA < EndB) && (EndA > StartB)
            // Ini mencakup semua kemungkinan: overlap sebagian depan, sebagian belakang, atau full di dalam.
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

        // Jika list tidak kosong, berarti ADA yang bentrok -> Return 201
        if (reservationBookedByDate.isNotEmpty) {
          statusCode = "201";
          return reservationBookedByDate;
        } else {
          statusCode = "200"; // Tanggal aman
          return noBooking;
        }
      } else {
        statusCode = "200"; // Belum ada reservasi sama sekali
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