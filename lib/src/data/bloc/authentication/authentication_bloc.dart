import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/repositories.dart';

import '../../utils/notification_services.dart';
import 'package:flutter/foundation.dart';

part 'authentication_event.dart';

part 'authentication_state.dart';

// BLoC ini bertindak sebagai "Jembatan" antara UI (Halaman Login/Splash) dan Data (API/Repository).
// Tugas utamanya: Mengurus logika login, menyimpan sesi user (session), dan mendaftarkan notifikasi.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {

  // Repositories dipanggil di sini untuk akses ke API (Login & Update Token FCM).
  Repositories repositories;

  // Service untuk mengambil Device Token (Firebase Cloud Messaging).
  final NotificationServices _notificationServices = NotificationServices();

  AuthenticationBloc({required this.repositories}) : super(LoginInitial()) {
    // on<InitialLogin>: Dijalankan saat aplikasi baru dibuka (biasanya di Splash Screen).
    on<InitialLogin>(_initialLogin);

    // on<OnLogin>: Dijalankan saat user menekan tombol "Login".
    on<OnLogin>(_loginEvent);
  }

  // ===========================================================================
  // 1. LOGIKA CEK SESI (AUTO LOGIN)
  // ===========================================================================
  // Fungsi ini mengecek apakah user sudah pernah login sebelumnya.
  // Caranya dengan mengecek data di penyimpanan lokal HP (SharedPreferences).
  _initialLogin(InitialLogin event, Emitter<AuthenticationState> emit) async {
    final token = await _getToken();
    final role = await _getRole();

    // Jika token ada (tidak null), berarti user masih login.
    if (token != null) {
      // Cek Role untuk mengarahkan ke halaman yang sesuai (Routing).
      if (role == "0") {
        emit(IsSuperAdmin()); // Masuk ke dashboard Super Admin
      } else if (role == "1") {
        emit(IsAdmin());      // Masuk ke dashboard Admin/Supervisor
      } else if (role == "2") {
        emit(IsUser());       // Masuk ke dashboard User biasa
      } else {
        emit(UnAuthenticated()); // Role tidak dikenali, suruh login ulang
      }
    } else {
      // Jika token tidak ada, berarti user belum login.
      emit(UnAuthenticated());
    }
  }

  // ===========================================================================
  // 2. LOGIKA LOGIN UTAMA
  // ===========================================================================
  _loginEvent(OnLogin event, Emitter<AuthenticationState> emit) async {
    // 1. Emit LoginLoading: Agar UI menampilkan indikator loading (lingkaran muter).
    emit(LoginLoading());
    try {
      // 2. Memanggil API Login melalui Repository.
      // Keyword 'await' penting agar aplikasi menunggu respon server sebelum lanjut.
      await repositories.authentication.login(event.username, event.password);

      // 3. Cek apakah login berhasil (token terisi dari respon API).
      if (repositories.authentication.token != "") {

        // 4. Simpan data penting ke memori HP (SharedPreferences).
        // Ini agar saat aplikasi ditutup dan dibuka lagi, user tidak perlu login ulang.
        await _saveUserToken(
          repositories.authentication.token,
          repositories.authentication.role,
          repositories.authentication.user, // Nama/Username
          repositories.authentication.agency, // Asal instansi/sekolah
        );
        final role = await _getRole();

        // (sebelum emit status sukses)
        try {
          // ===================================================================
          // 5. LOGIKA UPDATE TOKEN NOTIFIKASI (FCM)
          // ===================================================================
          // Hanya simpan token jika dia user biasa (role "2").
          // Admin (role "1") & Superadmin (role "0") tidak perlu terima notif status reservasi.
          if (role == "2") {
            // Ambil token unik HP user saat ini.
            final String? token = await _notificationServices.getDeviceToken();
            if (token != null) {
              // Kirim token HP ini ke database server.
              // Tujuannya: Agar server tahu ke HP mana notifikasi harus dikirim
              // jika reservasi user ini disetujui/ditolak.
              // .toLowerCase() digunakan karena username di database mungkin case-sensitive/lowercase.
              await repositories.user
                  .updateUserFCMToken(event.username.toLowerCase(), token);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print("Gagal menyimpan FCM Token saat login: $e");
          }
          // Error di sini di-catch (ditangkap) tapi tidak di-rethrow.
          // Artinya: Jika notifikasi gagal disetting, user TETAP BISA LOGIN.
          // Login lebih prioritas daripada fitur notifikasi.
        }

        // 6. Emit State Sukses sesuai Role (Memicu perpindahan halaman).
        if (role == "0") {
          emit(IsSuperAdmin());
        } else if (role == "1") {
          emit(IsAdmin());
        } else if (role == "2") {
          emit(IsUser());
        }
      } else {
        // Jika token kosong (biasanya karena password salah), kirim pesan error.
        emit(LoginFailed(repositories.authentication.error));
      }
    } catch (e) {
      // Jika terjadi error koneksi atau server down.
      throw Exception(e);
    }
  }

  ///Function for save token after success login
  // Helper: Menyimpan data ke SharedPreferences (Key-Value Storage).
  _saveUserToken(String token, String role, String user, String agency) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
    await prefs.setString("role", role);
    await prefs.setString("user", user);
    await prefs.setString("agency", agency);
  }

  ///Get Role
  // Helper: Mengambil data Role dari memori HP.
  _getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  ///Get Token
  // Helper: Mengambil Token Auth dari memori HP.
  _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }
}