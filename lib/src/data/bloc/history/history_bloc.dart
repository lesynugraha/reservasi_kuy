import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/history_model.dart';
import '../../repositories/repositories.dart';

part 'history_event.dart';
part 'history_state.dart';

// HistoryBloc ini unik karena melayani dua peran sekaligus (User & Admin).
// 1. Bagi User: Berfungsi sebagai "History" (Riwayat aktivitas pribadi).
// 2. Bagi Admin: Berfungsi sebagai "Report" (Laporan semua kegiatan di sekolah tersebut).
// Logic pemisahan datanya ada di fungsi _getHistoryUser (filter by username) vs _getReportAdmin (filter by agency).
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  Repositories repositories;

  HistoryBloc({required this.repositories}) : super(HistoryInitial()) {
    on<InitialHistory>(_initialHistory);
    on<GetHistoryUser>(_getHistoryUser);
    on<CreateHistory>(_createHistory);
    on<GetReportAdmin>(_getReportAdmin);
    on<CreateReport>(_createReport);
    on<CreateReportCustomId>(_createReportCustomId);
    on<UpdateFinishedReport>(_updateFinishedReport);
  }

  /// umum: initial history
  _initialHistory(InitialHistory event, Emitter<HistoryState> emit) {
    emit(HistoryInitial());
  }

  /// user: mendapatkan informasi riwayat
  // Fungsi ini dipanggil di halaman 'History' pada akun User Biasa.
  // PENTING: Kita memfilter data berdasarkan 'username' yang didapat dari Shared Preferences.
  // Tujuannya: Agar user A tidak bisa melihat riwayat peminjaman user B. (Data Privacy).
  _getHistoryUser(GetHistoryUser event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final user = await _getUsername(); // Ambil siapa yang sedang login
      final histories = await repositories.history.getHistory(user); // Minta data ke Firebase khusus user itu
      if (repositories.history.statusCode == "200") {
        emit(HistoryGetSuccess(histories));
      } else {
        emit(HistoryGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// user: membuat riwayat
  // Fungsi ini dipanggil setelah Reservasi berhasil dibuat.
  // Ini mencatat "Jejak Audit" bahwa transaksi telah terjadi.
  // Parameter 'proofImage' di sini penting, itu adalah Bukti Pembayaran/Transfer yang diupload user.
  _createHistory(CreateHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final agency = await _getAgency();
      await repositories.history.createHistory(
        event.buildingName,
        event.dateStart,
        event.dateEnd,
        event.dateCreated,
        DateTime.now().toString(),
        event.contactId,
        event.contactName,
        event.information,
        event.status,
        agency,
        event.image,
        note: event.note,
        proofImage: event.proofImage, // <--- PASSING DATA (Bukti Bayar)
      );
      if (repositories.history.statusCode == "200") {
        emit(HistoryCreateSuccess());
        // Auto-Refresh: Langsung tarik data terbaru supaya list riwayat user update otomatis.
        add(GetHistoryUser());
      } else {
        emit(HistoryCreateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// user: update laporan diselesaikan
  // Fungsi untuk mengubah status kegiatan menjadi "Selesai" atau "Finished".
  // Biasanya tombol ini muncul jika tanggal kegiatan sudah lewat.
  _updateFinishedReport(
      UpdateFinishedReport event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      await repositories.history.updateFinishedReport(event.id);
      if (repositories.history.statusCode == "200") {
        emit(HistoryUpdateSuccess());
        // Refresh lagi agar status di UI berubah dari "Disetujui" menjadi "Selesai".
        add(GetHistoryUser());
      } else {
        emit(HistoryUpdateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: membuat laporan
  // Ini fitur manual bagi Admin untuk mencatat kegiatan jika ada peminjaman offline (datang langsung).
  // Admin bisa menginput data peminjam secara manual ke dalam sistem agar jadwal gedung tetap tercatat penuh.
  _createReport(CreateReport event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final agency = await _getAgency();
      await repositories.history.createReport(
        event.buildingName,
        event.dateStart,
        event.dateEnd,
        event.dateCreated,
        event.contactId,
        event.contactName,
        event.information,
        event.status,
        agency, // Otomatis masuk ke instansi admin yang login
        event.image,
        note: event.note,
        proofImage: event.proofImage, // <--- PASSING DATA
      );
      if (repositories.history.statusCode == "200") {
        emit(HistoryCreateSuccess());
        // Refresh list laporan admin
        add(GetReportAdmin());
      } else {
        emit(HistoryCreateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: membuat laporan custom id
  // Mirip dengan createReport biasa, tapi di sini ID dokumennya ditentukan manual (custom).
  // Biasanya digunakan untuk kebutuhan migrasi data atau jika ID harus mengikuti format tertentu.
  _createReportCustomId(
      CreateReportCustomId event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final agency = await _getAgency();
      await repositories.history.createReportCustomId(
        event.id,
        event.buildingName,
        event.dateStart,
        event.dateEnd,
        event.dateCreated,
        event.contactId,
        event.contactName,
        event.information,
        event.status,
        agency,
        event.image,
        note: event.note,
        proofImage: event.proofImage, // <--- PASSING DATA
      );
      if (repositories.history.statusCode == "200") {
        emit(HistoryCreateSuccess());
        add(GetReportAdmin());
      } else {
        emit(HistoryCreateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: mendapatkan informasi laporan
  // Fungsi ini dipanggil di halaman 'Report' milik Admin.
  // BERBEDA dengan User:
  // Kalau User difilter berdasarkan 'Nama User' (Hanya lihat punya sendiri).
  // Kalau Admin difilter berdasarkan 'Agency/Sekolah' (Lihat semua peminjaman di sekolah itu).
  _getReportAdmin(GetReportAdmin event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final agency = await _getAgency();
      final histories = await repositories.history.getReportByAgency(agency);
      if (repositories.history.statusCode == "200") {
        emit(HistoryGetSuccess(histories));
      } else {
        emit(HistoryGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// umum: mendapatkan username
  _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user");
  }

  /// umum: mendapatkan instansi
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}