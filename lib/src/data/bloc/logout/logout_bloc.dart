import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../repositories/repositories.dart';

part 'logout_event.dart';

part 'logout_state.dart';

/// BLoC ini khusus menangani logika keluar aplikasi (Logout).
/// Memisahkan logic logout dari logic login agar kode lebih terstruktur (Separation of Concerns).
class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  // Menggunakan repository untuk akses fungsi logout di layer data (API/Firebase)
  Repositories repositories;

  LogoutBloc({required this.repositories}) : super(LogoutInitial()) {
    // Mendaftarkan event listener: saat event OnLogout dipanggil, jalankan fungsi logoutEvent
    on<InitialLogout>(initialLogout);
    on<OnLogout>(logoutEvent);
  }

  /// Reset state ke kondisi awal jika diperlukan
  initialLogout(InitialLogout event, Emitter<LogoutState> emit) {
    emit(LogoutInitial());
  }

  /// Fungsi utama eksekusi logout
  logoutEvent(OnLogout event, Emitter<LogoutState> emit) async {
    // 1. Emit loading agar UI menampilkan indikator proses (circular progress)
    emit(LogoutLoading());
    try {
      // 2. Panggil fungsi logout di repository (menghapus sesi/token di SharedPreferences & Firebase Auth)
      // Menggunakan await karena proses penghapusan data bersifat asynchronous
      await repositories.authentication.logout();

      // 3. Cek status dari repository, jika 200 (OK/Sukses)
      if (repositories.authentication.statusCode == "200") {
        // 4. Emit state sukses. State ini akan ditangkap oleh UI (BlocListener)
        // untuk menavigasi user kembali ke halaman Login (Route Replacement)
        emit(LogoutSuccess());
      }
    } catch (e) {
      // Exception handling untuk mencegah aplikasi crash jika proses logout gagal
      throw Exception(e);
    }
  }
}