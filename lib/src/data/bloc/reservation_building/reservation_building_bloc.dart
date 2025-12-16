import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/building_model.dart';
import '../../repositories/repositories.dart';

part 'reservation_building_event.dart';

part 'reservation_building_state.dart';

/// BLoC ini secara khusus menangani logic pengambilan data gedung yang BERSTATUS AKTIF.
/// Digunakan pada halaman form reservasi agar user hanya bisa memilih gedung yang tersedia (Available).
/// Dipisahkan dari 'BuildingBloc' utama (CRUD) untuk menjaga prinsip Single Responsibility.
class ReservationBuildingBloc
    extends Bloc<ReservationBuildingEvent, ReservationBuildingState> {
  Repositories repositories;

  ReservationBuildingBloc({required this.repositories})
      : super(ReservationBuildingInitial()) {
    on<InitialBuildingAvail>(_initialBuildingAvail);
    on<GetBuildingAvail>(_getBuildingAvail);
  }

  /// Reset state ke kondisi awal
  _initialBuildingAvail(
      InitialBuildingAvail event, Emitter<ReservationBuildingState> emit) {
    emit(ResBuInitial());
  }

  /// Fungsi utama untuk fetch data gedung ke dalam dropdown form reservasi.
  _getBuildingAvail(
      GetBuildingAvail event, Emitter<ReservationBuildingState> emit) async {
    // 1. Set state loading agar UI menampilkan indikator progress
    emit(ResBuLoading());
    try {
      // 2. Ambil filter instansi dari session user yang sedang login
      final agency = await _getAgency();

      // 3. Panggil repository khusus 'getBuildingAvailable'.
      // Berbeda dengan getBuilding biasa, fungsi ini hanya mengembalikan gedung
      // yang tidak sedang dalam perbaikan/renovasi (Status Aktif).
      final buildings =
      await repositories.building.getBuildingAvailable(agency);

      // 4. Validasi respon server
      if (repositories.building.statusCode == "200") {
        emit(ResBuGetSuccess(buildings));
      } else {
        emit(ResBuGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// Helper: Mengambil data agency/sekolah dari local storage (Shared Preferences)
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}