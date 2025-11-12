import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Pastikan import ini ada agar HistoryModel dikenali di state
import '../../model/history_model.dart';
import '../../repositories/repositories.dart';

part 'history_event.dart';
part 'history_state.dart';

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
  _getHistoryUser(GetHistoryUser event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final user = await _getUsername();
      final histories = await repositories.history.getHistory(user);
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
        note: event.note, // <--- MENGIRIM NOTE
      );
      if (repositories.history.statusCode == "200") {
        emit(HistoryCreateSuccess());
        add(GetHistoryUser());
      } else {
        emit(HistoryCreateFailed());
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// user: update laporan diselesaikan
  _updateFinishedReport(
      UpdateFinishedReport event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      await repositories.history.updateFinishedReport(event.id);
      if (repositories.history.statusCode == "200") {
        emit(HistoryUpdateSuccess()); // <--- SEKARANG CLASS INI SUDAH ADA
        add(GetHistoryUser());
      } else {
        emit(HistoryUpdateFailed()); // <--- CLASS INI JUGA
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// admin: membuat laporan
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
        agency,
        event.image,
        note: event.note, // <--- MENGIRIM NOTE
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

  /// admin: membuat laporan custom id
  _createReportCustomId(CreateReportCustomId event, Emitter<HistoryState> emit) async {
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
        note: event.note, // <--- MENGIRIM NOTE
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