import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reservation_app/src/data/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../repositories/repositories.dart';

part 'user_event.dart';

part 'user_state.dart';

/// BLoC ini menangani state untuk fitur Profil Pengguna (User Profile).
/// Berbeda dengan RegisterBloc yang mengelola daftar banyak user,
/// UserBloc fokus pada manajemen data diri user yang sedang login saat ini (Single User).
class UserBloc extends Bloc<UserEvent, UserState> {
  Repositories repositories;

  UserBloc({required this.repositories}) : super(UserInitial()) {
    on<InitialUser>(_initialUser);
    on<GetUserLoggedIn>(_getUserLoggedIn);
    on<EditSingleUser>(_editSingleUser);
    on<EditProfilePicture>(_editProfilePicture);
    on<EditPassword>(_editPassword);
  }

  _initialUser(InitialUser event, Emitter<UserState> emit) {
    emit(UserInitial());
  }

  /// Mengambil informasi lengkap user yang sedang login.
  /// Flow: Ambil username dari SharedPrefs -> Request data ke Server -> Tampilkan di UI.
  _getUserLoggedIn(GetUserLoggedIn event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // Identifikasi user berdasarkan username di local storage
      final username = await _getUsername();
      final user = await repositories.user.getUser(username);

      // Validasi respon dari repository
      if (repositories.user.statusCode == "200") {
        emit(UserGetSuccess(user));
      } else {
        emit(UserGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Logika untuk update data diri (Nama, Email, No HP, dll).
  _editSingleUser(EditSingleUser event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      await repositories.user.editUser(
        event.id,
        event.agency,
        event.username,
        event.password,
        event.fullName,
        event.email,
        event.phone,
      );
      if (repositories.user.statusCode == "200") {
        emit(EditSingleUserSuccess());
        // Auto-Refresh: Ambil data terbaru segera setelah update berhasil
        // agar tampilan profil langsung berubah tanpa user perlu refresh manual.
        add(GetUserLoggedIn());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Logika khusus untuk mengganti foto profil.
  /// Memisahkan logic upload gambar agar lebih modular.
  _editProfilePicture(EditProfilePicture event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      await repositories.user.editProfilePicture(
        event.id,
        event.image,
      );
      if (repositories.user.statusCode == "200") {
        emit(EditSingleUserSuccess());
        // Refresh data user untuk menampilkan URL gambar terbaru
        add(GetUserLoggedIn());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Logika ganti password.
  /// Memerlukan validasi password lama di sisi backend.
  _editPassword(EditPassword event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      await repositories.user.editPassword(
        event.id,
        event.username,
        event.oldPassword,
        event.newPassword,
      );
      // Cek apakah ada error specific (misal: password lama salah)
      if (repositories.user.error == "") {
        emit(EditPasswordSuccess());
        add(GetUserLoggedIn());
      } else {
        emit(EditPasswordFailed(repositories.user.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Helper: Mengambil username dari sesi lokal (Shared Preferences)
  /// Digunakan sebagai key/parameter utama untuk mengambil data user dari database.
  _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user");
  }
}