part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class InitialHistory extends HistoryEvent {}

class GetHistoryUser extends HistoryEvent {}

class GetReportAdmin extends HistoryEvent {}

class UpdateFinishedReport extends HistoryEvent {
  final String id;

  const UpdateFinishedReport(this.id);
}

class CreateHistory extends HistoryEvent {
  final String buildingName;
  final String dateStart;
  final String dateEnd;
  final String dateCreated;
  final String contactId;
  final String contactName;
  final String information;
  final String status;
  final String image;
  final String? note;
  final String? proofImage; // <--- [BARU]

  const CreateHistory(
      this.buildingName,
      this.dateStart,
      this.dateEnd,
      this.dateCreated,
      this.contactId,
      this.contactName,
      this.information,
      this.status,
      this.image, {
        this.note,
        this.proofImage, // <--- [BARU]
      });
}

class CreateReport extends HistoryEvent {
  final String buildingName;
  final String dateStart;
  final String dateEnd;
  final String dateCreated;
  final String contactId;
  final String contactName;
  final String information;
  final String status;
  final String image;
  final String? note;
  final String? proofImage; // <--- [BARU]

  const CreateReport(
      this.buildingName,
      this.dateStart,
      this.dateEnd,
      this.dateCreated,
      this.contactId,
      this.contactName,
      this.information,
      this.status,
      this.image, {
        this.note,
        this.proofImage, // <--- [BARU]
      });
}

class CreateReportCustomId extends HistoryEvent {
  final String id;
  final String buildingName;
  final String dateStart;
  final String dateEnd;
  final String dateCreated;
  final String contactId;
  final String contactName;
  final String information;
  final String status;
  final String image;
  final String? note;
  final String? proofImage; // <--- [BARU]

  const CreateReportCustomId(
      this.id,
      this.buildingName,
      this.dateStart,
      this.dateEnd,
      this.dateCreated,
      this.contactId,
      this.contactName,
      this.information,
      this.status,
      this.image, {
        this.note,
        this.proofImage, // <--- [BARU]
      });
}