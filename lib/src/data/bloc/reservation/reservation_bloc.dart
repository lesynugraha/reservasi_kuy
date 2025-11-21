import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../presentation/utils/general/image_picker.dart';

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

  _reservationInitial(
      InitialReservation event, Emitter<ReservationState> emit) {
    emit(ReservationInitial());
  }

  // --- LOGIC BARU REALTIME UNTUK USER ---
  _getReservationForUser(
      GetReservationForUser event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final user = await _getUsername();
      // Menggunakan emit.forEach untuk Stream
      await emit.forEach(
        repositories.reservation.getReservationStreamForUser(user),
        onData: (List<ReservationModel> data) {
          return ReservationGetSuccess(data);
        },
        onError: (_, __) => ReservationGetFailed(),
      );
    } catch (e) {
      emit(ReservationGetFailed());
    }
  }

  // --- LOGIC BARU REALTIME UNTUK ADMIN ---
  _getReservationForAccept(
      GetReservationForAdmin event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      final agency = await _getAgency();
      // Menggunakan emit.forEach untuk Stream
      await emit.forEach(
        repositories.reservation.getReservationStreamForAdmin(agency),
        onData: (List<ReservationModel> data) {
          return ReservationGetSuccess(data);
        },
        onError: (_, __) => ReservationGetFailed(),
      );
    } catch (e) {
      emit(ReservationGetFailed());
    }
  }

  _createReservation(
      CreateReservation event, Emitter<ReservationState> emit) async {
    emit(ReservationLoading());
    try {
      String proofImageUrl = "";
      if (event.fileProof != null) {
        String fileName = "proof_${DateTime.now().millisecondsSinceEpoch}";
        proofImageUrl = await StoreData().uploadImageToStorage(
            "reservation_proofs", fileName, event.fileProof!);
      }

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
        proofImageUrl,
      );

      if (repositories.reservation.statusCode == "200") {
        emit(ReservationCreateSuccess());
        // Tidak perlu add(GetReservationForUser()) lagi karena Stream akan otomatis update
      } else {
        emit(ReservationCreateFailed());
      }
    } catch (e) {
      emit(ReservationCreateFailed());
    }
  }

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
      } if(repositories.reservation.statusCode == "200"){
        emit(ReservationNoBooked());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  _deleteReservation(
      DeleteReservation event, Emitter<ReservationState> emit) async {
    // Note: Saat delete, tidak perlu emit Loading agar stream tidak putus visualnya
    // atau biarkan loading sebentar.
    try {
      await repositories.reservation.deleteReservation(event.id);
      if (repositories.reservation.statusCode == "200") {
        emit(ReservationDeleteSuccess());
        // Stream otomatis update UI
      } else {
        emit(ReservationDeleteFailed());
      }
    } catch (e) {
      emit(ReservationDeleteFailed());
    }
  }

  _updateStatusReservation(
      UpdateStatusReservation event, Emitter<ReservationState> emit) async {
    try {
      await repositories.reservation.updateStatusReservation(
          event.id,
          event.status,
          note: event.note
      );

      if (repositories.reservation.statusCode == "200") {
        emit(ReservationUpdateSuccess());
        // Stream otomatis update UI
      } else {
        emit(ReservationUpdateFailed());
      }
    } catch (e) {
      emit(ReservationUpdateFailed());
    }
  }

  _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("user");
  }

  _getAgency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("agency");
  }
}