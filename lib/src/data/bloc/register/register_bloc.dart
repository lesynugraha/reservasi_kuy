import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/user_model.dart';
import '../../repositories/repositories.dart';

part 'register_event.dart';

part 'register_state.dart';

/// Bloc ini berfungsi sebagai "User Management Controller".
/// Menangani logika pembuatan akun baru (Register), menampilkan daftar user,
/// serta fitur Edit dan Delete user oleh Admin maupun Super Admin.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  Repositories repositories;

  RegisterBloc({required this.repositories}) : super(RegisterInitialState()) {
    // Mapping event ke function logic yang sesuai
    on<InitialRegisterEvent>(initialRegister);
    on<Register>(register);
    on<GetAllUserAdmin>(getAllUserAdmin);
    on<GetAllUserSuperAdmin>(getAllUserSuperAdmin);
    on<DeleteUser>(deleteUser);
    on<DeleteUserSuperAdmin>(deleteUserSuperAdmin);
    on<EditUserAdmin>(editUserAdmin);
    on<ChangeUsername>(changeUsername);
  }

  /// Reset state ke kondisi awal
  initialRegister(InitialRegisterEvent event, Emitter<RegisterState> emit) {
    emit(RegisterInitialState());
  }

  /// Logic untuk menambah user baru ke database.
  /// Digunakan oleh Admin (tambah user sekolah) dan Super Admin (tambah admin sekolah).
  register(Register event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final userRole = await _getRole(); // Cek siapa yang sedang melakukan input

      // Kirim data registrasi ke repository
      await repositories.user.register(
        event.agency,
        event.username,
        event.password,
        event.fullName,
        event.role,
      );

      // Jika tidak ada error dari server
      if (repositories.user.error == "") {
        emit(RegisterSuccess());

        // Auto-Refresh Logic:
        // Setelah user baru berhasil dibuat, langsung panggil fungsi Get Data
        // agar list user di tampilan admin langsung terupdate tanpa refresh manual.
        if (userRole == "0") {
          add(GetAllUserSuperAdmin());
        } else if (userRole == "1") {
          add(GetAllUserAdmin());
        }
      } else {
        // Jika username sudah ada atau password kurang kuat
        emit(RegisterFailed(repositories.user.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Mengambil daftar user khusus untuk instansi/sekolah yang sedang login.
  /// Logic: Filter data user berdasarkan 'agency' dari admin yang login.
  getAllUserAdmin(GetAllUserAdmin event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final agency = await _getAgency();
      final users = await repositories.user.getAllUserByAgency(agency);
      if (repositories.user.statusCode == "200") {
        emit(GetAllUserSuccess(users));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Mengambil SELURUH data user di sistem (Global Access).
  /// Fitur khusus Super Admin untuk memantau semua sekolah.
  getAllUserSuperAdmin(
      GetAllUserSuperAdmin event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final users = await repositories.user.getAllUserSuperAdmin();
      if (repositories.user.statusCode == "200") {
        emit(GetAllUserSuccess(users));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Menghapus user berdasarkan ID.
  deleteUser(DeleteUser event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final userRole = await _getRole();
      await repositories.user.deleteUser(event.id);

      if (repositories.user.statusCode == "200") {
        emit(DeleteSuccess());
        // Refresh list setelah hapus berhasil
        if (userRole == "0") {
          add(GetAllUserSuperAdmin());
        } else if (userRole == "1") {
          add(GetAllUserAdmin());
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Fitur Super Admin: Menghapus user berdasarkan Agency.
  /// (Biasanya dipakai untuk reset data satu sekolah).
  deleteUserSuperAdmin(DeleteUserSuperAdmin event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final userRole = await _getRole();
      await repositories.user.deleteUserSuperAdmin(event.agency);
      if (repositories.user.statusCode == "200") {
        emit(DeleteSuccess());
        if (userRole == "0") {
          add(GetAllUserSuperAdmin());
        } else if (userRole == "1") {
          add(GetAllUserAdmin());
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Logic untuk mengedit profil user (Nama, Email, No HP).
  editUserAdmin(EditUserAdmin event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final userRole = await _getRole();
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
        emit(EditSuccess());
        // Refresh list user setelah update
        if (userRole == "0") {
          add(GetAllUserSuperAdmin());
        } else if (userRole == "1") {
          add(GetAllUserAdmin());
        }
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Logic khusus mengubah username.
  /// Dipisahkan karena username bersifat unik dan primary key di beberapa case auth,
  /// jadi perlu validasi khusus dari backend.
  changeUsername(ChangeUsername event, Emitter<RegisterState> emit) async {
    emit(RegisterLoading());
    try {
      final userRole = await _getRole();
      await repositories.user.changeUsername(
        event.id,
        event.username,
      );
      if (repositories.user.error == "") {
        emit(ChangeUsernameSuccess());
        if (userRole == "0") {
          add(GetAllUserSuperAdmin());
        } else if (userRole == "1") {
          add(GetAllUserAdmin());
        }
      } else {
        emit(ChangeUsernameFailed(repositories.user.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Helper: Mengambil nama instansi dari session storage
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }

  /// Helper: Mengambil role user dari session storage
  _getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }
}