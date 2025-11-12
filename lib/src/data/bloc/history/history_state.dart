part of 'history_bloc.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  @override
  List<Object> get props => [];
}

class HistoryLoading extends HistoryState {
  @override
  List<Object> get props => [];
}

class HistoryGetSuccess extends HistoryState {
  final List<HistoryModel> histories;

  const HistoryGetSuccess(this.histories);

  @override
  List<Object> get props => [histories];
}

class HistoryGetFailed extends HistoryState {
  @override
  List<Object> get props => [];
}

class HistoryCreateSuccess extends HistoryState {
  @override
  List<Object> get props => [];
}

class HistoryCreateFailed extends HistoryState {
  @override
  List<Object> get props => [];
}

// vvv INI YANG HILANG DAN MENYEBABKAN ERROR vvv
class HistoryUpdateSuccess extends HistoryState {
  @override
  List<Object> get props => [];
}

class HistoryUpdateFailed extends HistoryState {
  @override
  List<Object> get props => [];
}
// ^^^ SUDAH DITAMBAHKAN ^^^