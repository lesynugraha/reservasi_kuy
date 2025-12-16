import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/extracurricular_model.dart';
import '../../repositories/repositories.dart';

part 'extracurricular_event.dart';

part 'extracurricular_state.dart';

// BLoC ini khusus menangani logika bisnis untuk fitur Ekstrakurikuler.
// Berfungsi untuk menghubungkan input user (CRUD Ekskul) dengan Repository (Database).
class ExtracurricularBloc extends Bloc<ExtracurricularEvent, ExtracurricularState> {
  // Repository disuntikkan (Dependency Injection) agar BLoC bisa memanggil fungsi API.
  Repositories repositories;

  ExtracurricularBloc({required this.repositories}) : super(ExtracurricularInitial()) {
    // Mendaftarkan Event Handler:
    on<InitialExtracurricular>(_initialExschool);
    on<GetExtracurricular>(_getExschool);
    on<AddExtracurricular>(_addExschool);
    on<UpdateExtracurricular>(_updateExschool);
    on<DeleteExtracurricular>(_deleteExschool);
  }

  _initialExschool(InitialExtracurricular event, Emitter<ExtracurricularState> emit) {}

  // ===========================================================================
  // READ: MENGAMBIL DATA EKSKUL
  // ===========================================================================
  _getExschool(GetExtracurricular event, Emitter<ExtracurricularState> emit) async {
    emit(ExtracurricularLoading()); // Set status loading (spinner muncul)
    try {
      // 1. Ambil identitas sekolah (agency) dari sesi login.
      // Ini PENTING: Agar ekskul SMAN 1 tidak bercampur dengan sekolah lain jika aplikasi dikembangkan.
      final agency = await _getAgency();

      // 2. Minta data ke Repository berdasarkan nama sekolah tersebut.
      final exschools = await repositories.exschool.getExschoolByAgency(agency);

      // 3. Cek respon server.
      if (repositories.exschool.statusCode == "200") {
        emit(ExtracurricularGetSuccess(exschools)); // Tampilkan data ke List
      } else {
        emit(ExtracurricularGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///menambahkan exschool
  // ===========================================================================
  // CREATE: MENAMBAH EKSKUL BARU
  // ===========================================================================
  _addExschool(AddExtracurricular event, Emitter<ExtracurricularState> emit) async {
    emit(ExtracurricularLoading());
    try {
      final agency = await _getAgency();

      // Mengirim data inputan user (Nama, Deskripsi, Jadwal, Gambar) ke server.
      await repositories.exschool.addExcur(
        event.name,
        event.description,
        event.schedule, // Parameter jadwal kegiatan
        event.image,    // File gambar logo ekskul
        agency,
      );

      if (repositories.exschool.statusCode == "200") {
        emit(ExtracurricularAddSuccess());

        // LOGIKA AUTO-REFRESH:
        // Setelah sukses tambah, panggil event GetExtracurricular lagi.
        // Agar list di layar langsung update tanpa user perlu refresh manual.
        add(GetExtracurricular());
      }
      {
        emit(ExtracurricularAddFailed(repositories.exschool.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Update/edit Exschool
  // ===========================================================================
  // UPDATE: MENGEDIT DATA EKSKUL
  // ===========================================================================
  _updateExschool(UpdateExtracurricular event, Emitter<ExtracurricularState> emit) async {
    emit(ExtracurricularLoading());
    try {
      final agency = await _getAgency();
      await repositories.exschool.updateExschool(
        event.id,          // ID unik dokumen di Firebase (penting agar tahu mana yang diedit)
        event.name,
        event.description,
        event.schedule,
        event.image,       // Gambar baru (bisa null jika tidak diganti)
        agency,
        event.baseName,    // Nama file gambar lama (untuk dihapus dari Storage jika gambar diganti)
      );

      if (repositories.exschool.statusCode == "200") {
        emit(ExtracurricularUpdateSuccess());
        // Auto-refresh list setelah edit
        add(GetExtracurricular());
      }
      {
        emit(ExtracurricularUpdateFailed(repositories.exschool.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// menghapus exschool
  // ===========================================================================
  // DELETE: MENGHAPUS EKSKUL
  // ===========================================================================
  _deleteExschool(DeleteExtracurricular event, Emitter<ExtracurricularState> emit) async {
    emit(ExtracurricularLoading());
    try {
      // Hapus dokumen berdasarkan ID
      await repositories.exschool.deleteExschool(event.id);

      if (repositories.exschool.statusCode == "200") {
        emit(ExtracurricularDeleteSuccess());
        // Auto-refresh list setelah hapus
        add(GetExtracurricular());
      } else {
        emit(ExtracurricularDeleteFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Get Agency
  // Helper: Mengambil nama instansi dari penyimpanan lokal HP (Shared Preferences)
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}