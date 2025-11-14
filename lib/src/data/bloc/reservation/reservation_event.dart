part of 'reservation_bloc.dart';

abstract class ReservationEvent extends Equatable {
  const ReservationEvent();

  @override
  List<Object?> get props => [];
}

class InitialReservation extends ReservationEvent {}

class DeleteReservation extends ReservationEvent {
  final String id;

  const DeleteReservation(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateStatusReservation extends ReservationEvent {
  final String id;
  final String status;
  final String? note;

  const UpdateStatusReservation(
      this.id,
      this.status,
      {this.note}
      );

  @override
  List<Object?> get props => [id, status, note];
}

class GetReservationCheck extends ReservationEvent {
  final String dateStart;
  final String dateEnd;
  final String buildingName;

  const GetReservationCheck(this.dateStart, this.dateEnd, this.buildingName);

  @override
  List<Object?> get props => [dateStart, dateEnd, buildingName];
}

class CreateReservation extends ReservationEvent {
  final String buildingName;
  final String contactId;
  final String contactName;
  final String contactEmail;
  final String contactPhone;
  final String dateStart;
  final String dateEnd;
  final String information;
  final String agency;
  final String image;
  final Uint8List? fileProof; // Data gambar bukti

  const CreateReservation(
      this.buildingName,
      this.contactId,
      this.contactName,
      this.contactEmail,
      this.contactPhone,
      this.dateStart,
      this.dateEnd,
      this.information,
      this.agency,
      this.image,
      this.fileProof,
      );

  @override
  List<Object?> get props => [
    buildingName,
    contactId,
    contactName,
    contactEmail,
    contactPhone,
    dateStart,
    dateEnd,
    information,
    agency,
    image,
    // fileProof tidak perlu dimasukkan ke props untuk performa,
    // karena datanya besar (byte array) dan jarang dibandingkan secara equality.
  ];
}

class GetReservationForUser extends ReservationEvent {}

class GetReservationForAdmin extends ReservationEvent {}