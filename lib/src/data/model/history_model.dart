import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  String? id;
  String? buildingName;
  String? dateStart;
  String? dateEnd;
  String? dateCreated;
  String? dateFinished;
  String? contactId;
  String? contactName;
  String? information;
  String? status;
  String? image;
  String? agency;
  String? note;

  HistoryModel({
    this.id,
    this.buildingName,
    this.dateStart,
    this.dateEnd,
    this.dateCreated,
    this.dateFinished,
    this.contactId,
    this.contactName,
    this.information,
    this.status,
    this.image,
    this.agency,
    this.note,
  });

  // vvv TEKNIK ANTI-CRASH (SAFE PARSING) vvv
  factory HistoryModel.fromJson(dynamic json) {
    // Jika input adalah Snapshot dari Firestore
    if (json is DocumentSnapshot) {
      final data = json.data() as Map<String, dynamic>? ?? {};
      return HistoryModel(
        id: json.id,
        buildingName: data['buildingName'],
        dateStart: data['dateStart'],
        dateEnd: data['dateEnd'],
        dateCreated: data['dateCreated'],
        dateFinished: data['dateFinished'],
        contactId: data['contactId'],
        contactName: data['contactName'],
        information: data['information'],
        status: data['status'],
        image: data['image'],
        agency: data['agency'],
        // Kalau field note tidak ada, isi dengan "" (jangan crash)
        note: data['note'] ?? "",
      );
    }
    // Jika input adalah Map biasa
    else {
      final data = json as Map<String, dynamic>;
      return HistoryModel(
        id: data['id'],
        buildingName: data['buildingName'],
        dateStart: data['dateStart'],
        dateEnd: data['dateEnd'],
        dateCreated: data['dateCreated'],
        dateFinished: data['dateFinished'],
        contactId: data['contactId'],
        contactName: data['contactName'],
        information: data['information'],
        status: data['status'],
        image: data['image'],
        agency: data['agency'],
        note: data['note'] ?? "", // Aman
      );
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['buildingName'] = buildingName;
    map['dateStart'] = dateStart;
    map['dateEnd'] = dateEnd;
    map['dateCreated'] = dateCreated;
    map['dateFinished'] = dateFinished;
    map['contactId'] = contactId;
    map['contactName'] = contactName;
    map['information'] = information;
    map['status'] = status;
    map['image'] = image;
    map['agency'] = agency;
    map['note'] = note;
    return map;
  }
}