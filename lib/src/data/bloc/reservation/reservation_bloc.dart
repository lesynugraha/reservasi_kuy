import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/reservation_model.dart';
import '../../repositories/repositories.dart';

part 'reservation_event.dart';
part 'reservation_state.dart';

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  Repositories repositories;

  ReservationBloc({required this.repositories}) : super(ReservationInitial()) {
    on<InitialReservation>(_reservationInitial);
    on<GetReservationForUser>(_getReservationForUser);
    on<GetReservationForAdmin>(_getReservationForAccept);
    on<GetReservationCheck>(_getReservationCheck);
    on<UpdateStatusReservation>(_updateStatusReservation);
    on<CreateReservation>(_createReservation);
    on<DeleteReservation>(_deleteReservation);
  }

  /// reservasi awalan
  _reservationInitial(
      InitialReservation event, Emitter<ReservationState> emit) {
    emit(ReservationInitial());
  }

  /// membuat reservasi
  _createReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      await repositories.reservation.createReservation(
        event.buildingName,
        event.contactId,
        event.contactName,
        event.contactEmail,
        event.contactPhone,
        event.dateStart,
        event.dateEnd,
        DateTime.now().toString(),
        event.information,
        event.agency,
        event.image,
      );
      if (repositories.reservation.statusCode == "200") {
        emit(ReservationCreateSuccess());
        add(GetReservationForUser());
      } else {
        emit(ReservationCreateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// pengecekan reservasi awalan
  _getReservationCheck(
      GetReservationCheck event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final agency = await _getAgency();
      final booked = await repositories.reservation.getReservationAvail(
        event.dateStart,
        event.dateEnd,
        agency,
        event.buildingName,
      );
      if(repositories.reservation.statusCode == "201"){
        emit(ReservationBooked(booked));
        add(GetReservationForUser());
      } if(repositories.reservation.statusCode == "200"){
        emit(ReservationNoBooked());
        add(GetReservationForUser());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// mendapatkan info reservasi bagi pengguna
  _getReservationForUser(
      GetReservationForUser event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final user = await _getUsername();
      final reservations =
      await repositories.reservation.getReservationForUser(user);
      if (repositories.reservation.statusCode == "200") {
        emit(ReservationGetSuccess(reservations));
      } else {
        emit(ReservationGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// mendapatkan info reservasi untuk admin
  _getReservationForAccept(
      GetReservationForAdmin event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final agency = await _getAgency();
      final reservations =
      await repositories.reservation.getReservationForAdmin(agency);
      if (repositories.reservation.statusCode == "200") {
        emit(ReservationGetSuccess(reservations));
      } else {
        emit(ReservationGetFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// menghapus reservasi
  _deleteReservation(
      DeleteReservation event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      await repositories.reservation.deleteReservation(event.id);
      if (repositories.reservation.statusCode == "200") {
        emit(ReservationDeleteSuccess());
        add(GetReservationForUser());
      } else {
        emit(ReservationDeleteFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// terima/tolak reservasi bagi admin
  _updateStatusReservation(
      UpdateStatusReservation event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      // vvv INI BAGIAN KRUSIAL YANG ANDA LEWATKAN SEBELUMNYA vvv
      await repositories.reservation.updateStatusReservation(
          event.id,
          event.status,
          note: event.note // <--- Pastikan baris ini ada!
      );
      // ^^^ SELESAI ^^^

      if (repositories.reservation.statusCode == "200") {
        emit(ReservationUpdateSuccess());
        add(GetReservationForAdmin());
      } else {
        emit(ReservationUpdateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  //Get Username
  _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user");
  }

  //Get Agency
  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}
