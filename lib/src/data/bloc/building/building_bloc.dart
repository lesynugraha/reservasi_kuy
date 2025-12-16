import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/building_model.dart';
import '../../repositories/repositories.dart';

part 'building_event.dart';

part 'building_state.dart';

// Class BuildingBloc ini berfungsi sebagai 'Controller' utama untuk Manajemen Data Gedung.
// Menggunakan pattern BLoC untuk memisahkan logika bisnis (CRUD) dari tampilan (UI).
// Bloc ini menerima input berupa 'Event' (misal: tombol tambah diklik) dan menghasilkan output 'State' (misal: data berhasil disimpan).
class BuildingBloc extends Bloc<BuildingEvent, BuildingState> {
  // Repositories digunakan untuk komunikasi ke database (API Calls).
  Repositories repositories;

  BuildingBloc({required this.repositories}) : super(BuildingInitial()) {
    // Mendaftarkan Event Handler:
    // "Jika event X terjadi, jalankan fungsi Y"
    on<InitialBuilding>(_initialBuilding);
    on<GetBuildingSuperAdmin>(_getBuildingSuperAdmin);
    on<GetBuildingByAgency>(_getBuildingByAgency);
    on<AddBuilding>(_addBuilding);
    on<DeleteBuilding>(_deleteBuilding);
    on<UpdateBuilding>(_updateBuilding);
    on<ChangeStatusBuilding>(_changeStatusBuilding);
  }

  _initialBuilding(InitialBuilding event, Emitter<BuildingState> emit) {
    emit(BuildingInitial());
  }

  // Fungsi khusus Super Admin: Mengambil SEMUA data gedung tanpa filter sekolah.
  _getBuildingSuperAdmin(
      GetBuildingSuperAdmin event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading()); // Tampilkan loading spinner
    try {
      final buildings = await repositories.building.getBuilding();
      if (repositories.building.statusCode == "200") {
        emit(BuildingGetSuccess(buildings)); // Kirim data gedung ke UI
      } else {
        emit(BuildingGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Get building berdasarkan instansi (sekolah)
  // Fungsi ini menerapkan logika 'Multi-Tenancy' sederhana.
  // Karena aplikasi ini bisa dipakai banyak sekolah, User/Admin SMAN 1 Tanjung Bintang
  // HANYA BOLEH melihat gedung milik sekolah mereka sendiri.
  // Caranya dengan mengambil data 'agency' dari sesi login (SharedPrefs) dan mem-filter query database.
  _getBuildingByAgency(
      GetBuildingByAgency event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading());
    try {
      final agency = await _getAgency(); // Ambil nama sekolah user yang sedang login
      final buildings = await repositories.building.getBuildingByAgency(agency);

      if (repositories.building.statusCode == "200") {
        emit(BuildingGetSuccess(buildings));
      } else {
        emit(BuildingGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///menambahkan building
  _addBuilding(AddBuilding event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading());
    try {
      final agency = await _getAgency();
      // Mengirim data form input ke repository untuk disimpan ke Firebase
      await repositories.building.addBuilding(
        event.name,
        event.description,
        event.facility,
        event.capacity,
        event.rule,
        event.image, // Gambar yang diupload user
        agency,      // Otomatis diset sesuai sekolah user yang login
      );

      if (repositories.building.statusCode == "200") {
        emit(BuildingAddSuccess());
        // LOGIKA AUTO-REFRESH:
        // Setelah berhasil menambah data, kita panggil lagi event 'GetBuildingByAgency'.
        // Tujuannya agar list gedung di layar user langsung terupdate otomatis (real-time feel).
        add(GetBuildingByAgency());
      }
      {
        emit(BuildingAddFailed(repositories.building.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Update/edit building
  _updateBuilding(UpdateBuilding event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading());
    try {
      final agency = await _getAgency();
      await repositories.building.updateBuilding(
        event.id,
        event.name,
        event.description,
        event.facility,
        event.capacity,
        event.rule,
        event.image,
        agency,
        event.baseName, // Nama file gambar lama (perlu tahu ini untuk menghapusnya dari Storage jika gambar diganti)
        event.status,
      );

      if (repositories.building.statusCode == "200") {
        emit(BuildingUpdateSuccess());
        // Auto-refresh list setelah edit berhasil
        add(GetBuildingByAgency());
      }
      {
        emit(BuildingUpdateFailed(repositories.building.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Mengubah status
  _changeStatusBuilding(
      ChangeStatusBuilding event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading());
    try {
      await repositories.building.changeStatusBuilding(
        event.name,
      );

      if (repositories.building.statusCode == "200") {
        emit(BuildingUpdateSuccess());
        add(GetBuildingByAgency());
      }
      {
        emit(BuildingUpdateFailed(repositories.building.error));
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// menghapus building
  _deleteBuilding(DeleteBuilding event, Emitter<BuildingState> emit) async {
    emit(BuildingLoading());
    try {
      await repositories.building.deleteBuilding(event.id);
      if (repositories.building.statusCode == "200") {
        emit(BuildingDeleteSuccess());
        // Auto-refresh list setelah hapus berhasil
        add(GetBuildingByAgency());
      } else {
        emit(BuildingDeleteFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Get Agency
  // Helper function: Mengambil data string 'Agency' (Sekolah) dari penyimpanan lokal HP
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}