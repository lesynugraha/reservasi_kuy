import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  String? id;
  String? buildingName;
  String? contactId;
  String? contactName;
  String? contactEmail;
  String? contactPhone;
  String? dateStart;
  String? dateEnd;
  String? dateCreated;
  String? information;
  String? agency;
  String? status;
  String? image;
  String? note;

  ReservationModel({
    this.id,
    this.buildingName,
    this.contactId,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.dateStart,
    this.dateEnd,
    this.dateCreated,
    this.information,
    this.agency,
    this.status,
    this.image,
    this.note,
  });

  // vvv TEKNIK ANTI-CRASH (SAFE PARSING) vvv
  factory ReservationModel.fromJson(dynamic json) {
    if (json is DocumentSnapshot) {
      final data = json.data() as Map<String, dynamic>? ?? {};
      return ReservationModel(
        id: json.id,
        buildingName: data['buildingName'],
        contactId: data['contactId'],
        contactName: data['contactName'],
        contactEmail: data['contactEmail'],
        contactPhone: data['contactPhone'],
        dateStart: data['dateStart'],
        dateEnd: data['dateEnd'],
        dateCreated: data['dateCreated'],
        information: data['information'],
        agency: data['agency'],
        status: data['status'],
        image: data['image'],
        // Kalau field note tidak ada, isi dengan "" (jangan crash)
        note: data['note'] ?? "",
      );
    } else {
      final data = json as Map<String, dynamic>;
      return ReservationModel(
        id: data['id'],
        buildingName: data['buildingName'],
        contactId: data['contactId'],
        contactName: data['contactName'],
        contactEmail: data['contactEmail'],
        contactPhone: data['contactPhone'],
        dateStart: data['dateStart'],
        dateEnd: data['dateEnd'],
        dateCreated: data['dateCreated'],
        information: data['information'],
        agency: data['agency'],
        status: data['status'],
        image: data['image'],
        note: data['note'] ?? "",
      );
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['buildingName'] = buildingName;
    map['contactId'] = contactId;
    map['contactName'] = contactName;
    map['contactEmail'] = contactEmail;
    map['contactPhone'] = contactPhone;
    map['dateStart'] = dateStart;
    map['dateEnd'] = dateEnd;
    map['dateCreated'] = dateCreated;
    map['information'] = information;
    map['agency'] = agency;
    map['status'] = status;
    map['image'] = image;
    map['note'] = note;
    return map;
  }
}