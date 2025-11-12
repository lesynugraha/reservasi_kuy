// Sintaks V2: Impor dari /v2/firestore
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
// Logger baru yang lebih baik dari console.log
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

// Inisialisasi Admin SDK (cukup sekali di sini)
admin.initializeApp();

/**
 * Cloud Function V2
 * Terpicu saat dokumen di 'reservations' di-update
 */
export const onReservationStatusUpdate = onDocumentUpdated(
  {
    document: "reservations/{reservationId}",
    region: "asia-southeast2", // <-- Lokasi sudah benar
  },
  async (event) => {
    // Mulai logger
    logger.info("Fungsi onReservationStatusUpdate terpicu...");

    // Cek datanya
    if (!event.data) {
      logger.log("Tidak ada data di event, fungsi dihentikan.");
      return;
    }

    // Ambil data dokumen SEBELUM dan SESUDAH update
    const dataBefore = event.data.before.data();
    const dataAfter = event.data.after.data();

    // Cek apakah field 'status' benar-benar berubah
    if (dataBefore.status === dataAfter.status) {
      logger.log("Status tidak berubah, notifikasi tidak dikirim.");
      return;
    }

    // Cek apakah status baru adalah "Disetujui" atau "Ditolak"
    const newStatus = dataAfter.status;
    if (newStatus !== "Disetujui" && newStatus !== "Ditolak") {
      logger.log(`Status baru adalah ${newStatus}, notifikasi tidak dikirim.`);
      return;
    }

    logger.log(
      `Status berubah dari '${dataBefore.status}' ke '${newStatus}'.`,
      "Menyiapkan notifikasi...",
    );

    // 1. Dapatkan ID user dari dokumen reservasi
    const userId = dataAfter.contactId; // Sesuai model Anda [contactId]
    if (!userId) {
      logger.error("Dokumen reservasi tidak memiliki contactId.");
      return;
    }

    // 2. Cari dokumen user di koleksi 'users' untuk mendapatkan FCM Token-nya
    let userToken = "";
    try {
      // Sesuai UserModel Anda, kita cari berdasarkan 'username' [contactId]
      const userQuery = await admin.firestore().collection("users")
        .where("username", "==", userId).get();

      if (userQuery.empty) {
        logger.error(`User dengan username ${userId} tidak ditemukan.`);
        return;
      }

      // Ambil dokumen pertama yang cocok
      const userDoc = userQuery.docs[0];
      userToken = userDoc.data().fcmToken; // <-- KITA ASUMSIKAN 'fcmToken'

      if (!userToken) {
        logger.error(`User ${userId} tidak memiliki 'fcmToken'.`);
        return;
      }
    } catch (error) {
      logger.error("Error saat mengambil data user:", error);
      return;
    }

    // 3. Tentukan isi pesan notifikasi
    const statusText = dataAfter.status; // "Disetujui" atau "Ditolak"
    const buildingName = dataAfter.buildingName;

    // Kita gunakan objek 'Message' yang lengkap
    const message: admin.messaging.Message = {
      token: userToken,
      notification: {
        title: `Reservasi Anda ${statusText}!`,
        body: `Pengajuan Anda untuk ${buildingName} telah ` +
              `${statusText.toLowerCase()} oleh admin.`,
      },
      android: {
        priority: "high", // <-- INI KUNCINYA: "Prioritas Tinggi"
      },
      apns: { // <-- Ini untuk jaga-jaga jika dipakai di iPhone
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
    };

    // 4. Kirim notifikasi!
    try {
      // vvv INI BARIS YANG DIPERBAIKI (PECAH JADI 2 BARIS) vvv
      logger.log(
        `Mengirim notifikasi (prioritas tinggi) ke token: ${userToken}`,
      );
      // ^^^ AKHIR PERBAIKAN ^^^

      // Mengirim objek 'message' yang baru
      await admin.messaging().send(message);
      logger.log("Notifikasi berhasil dikirim.");
    } catch (error) {
      logger.error("Gagal mengirim notifikasi:", error);
    }
  });

