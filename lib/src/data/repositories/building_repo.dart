part of 'repositories.dart';

/// Class Repository ini bertindak sebagai Data Access Layer (DAL) untuk koleksi 'buildings'.
/// Menangani komunikasi langsung (CRUD) ke Firebase Firestore.
class BuildingRepo {
  late String statusCode;
  late String error;

  //This for superAdmin but add agency for the detail
  /// Mengambil SELURUH data gedung dari database tanpa filter.
  /// Digunakan oleh Super Admin untuk monitoring global.
  getBuilding() async {
    statusCode = "";
    try {
      // Mengambil snapshot dari collection 'buildings'
      QuerySnapshot resultBuilding =
      await Repositories().db.collection("buildings").get();

      // Mapping data dari DocumentSnapshot (format Firestore) ke Object Model (Dart)
      if (resultBuilding.docs.isNotEmpty) {
        statusCode = "200";
        final List<BuildingModel> buildings =
        resultBuilding.docs.map((e) => BuildingModel.fromJson(e)).toList();
        return buildings;
      } else {
        statusCode = "200"; // Sukses tapi data kosong
        final List<BuildingModel> buildings = [];
        return buildings;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// mendapatkan info gedung sesuai instansi
  /// Melakukan Query Filtering berdasarkan field 'agency'.
  /// Penting untuk memastikan admin sekolah A tidak melihat gedung sekolah B.
  getBuildingByAgency(String agency) async {
    statusCode = "";
    try {
      QuerySnapshot resultBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("agency", isEqualTo: agency) // Filter query di sisi Server (Firestore)
          .get();
      if (resultBuilding.docs.isNotEmpty) {
        statusCode = "200";
        final List<BuildingModel> buildings =
        resultBuilding.docs.map((e) => BuildingModel.fromJson(e)).toList();
        return buildings;
      } else {
        statusCode = "200";
        final List<BuildingModel> buildings = [];
        return buildings;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  /// menambahkan building
  addBuilding(
      String name,
      String description,
      String facility,
      int capacity,
      String rule,
      String image,
      String agency,
      ) async {
    statusCode = "";
    error = "";

    // Sanitasi input: Menghapus spasi berlebih agar nama file/data rapi
    final parsedBuildingName = ParsingString().removeMultiSpace(name);
    try {
      /// LOGIC VALIDASI DUPLIKASI:
      /// Sebelum insert, kita ambil dulu data gedung di agency ini.
      QuerySnapshot resultBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("agency", isEqualTo: agency)
          .get();

      final List<BuildingModel> listBuilding = resultBuilding.docs
          .map(
            (e) => BuildingModel.fromJson(e),
      )
          .toList();

      // Cek apakah nama gedung sudah ada (Case Insensitive)
      final buildingNameIsExist = listBuilding
          .where(
            (element) =>
        element.name?.toLowerCase() == parsedBuildingName.toLowerCase(),
      )
          .toList();

      if (buildingNameIsExist.isNotEmpty) {
        /// building is exist
        error = "Gedung sudah ada";
      } else {
        // Jika aman, lakukan Insert data baru
        await Repositories().db.collection("buildings").add({
          "id": "", // ID sementara kosong, nanti diupdate setelah doc terbentuk
          "name": parsedBuildingName,
          "description": description,
          "facility": facility,
          "capacity": capacity,
          "rule": rule,
          "image": image,
          "agency": agency,
          "status": "Tersedia", // Default status
        }).then(
              (value) {
            // Update field 'id' di dalam dokumen dengan ID otomatis dari Firestore
            // Agar mempermudah proses edit/delete nantinya.
            Repositories()
                .db
                .collection("buildings")
                .doc(value.id)
                .update({"id": value.id});
          },
        );
        statusCode = "200";
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Mengupdate atau mengedit building
  updateBuilding(
      String id,
      String name,
      String description,
      String facility,
      int capacity,
      String rule,
      String image,
      String agency,
      String baseName,
      String status,
      ) async {
    statusCode = "";
    error = "";
    final parsedBuildingName = ParsingString().removeMultiSpace(name);
    final parsedBuildingBaseName = ParsingString().removeMultiSpace(baseName);

    try {
      /// check if building already exist
      // Ambil semua data gedung
      QuerySnapshot resultBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("agency", isEqualTo: agency)
          .get();
      final List<BuildingModel> listBuilding = resultBuilding.docs
          .map(
            (e) => BuildingModel.fromJson(e),
      )
          .toList();

      // LOGIC PENTING SAAT UPDATE:
      // Hapus gedung yang sedang kita edit dari list pengecekan.
      // Jika tidak dihapus, sistem akan mengira nama gedung bentrok dengan dirinya sendiri.
      listBuilding.removeWhere(
            (element) =>
        element.name?.toLowerCase() == parsedBuildingBaseName.toLowerCase(),
      );

      // Cek duplikasi dengan gedung LAINNYA
      final buildingNameIsExist = listBuilding
          .where(
            (element) =>
        element.name?.toLowerCase() == parsedBuildingName.toLowerCase(),
      )
          .toList();

      if (buildingNameIsExist.isNotEmpty) {
        /// building is exist
        error = "Gedung sudah ada, coba yang lain";
      } else {
        // Lakukan update fields tertentu
        await Repositories().db.collection("buildings").doc(id).update({
          "name": parsedBuildingName,
          "description": description,
          "facility": facility,
          "capacity": capacity,
          "rule": rule,
          "image": image,
          "status": status,
        });
        statusCode = "200";
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Mendapatkan info gedung yang tersedia pada halaman reservasi
  getBuildingAvailable(String agency) async {
    statusCode = "";
    try {
      QuerySnapshot resultBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("agency", isEqualTo: agency)
          .get();
      if (resultBuilding.docs.isNotEmpty) {
        statusCode = "200";
        final List<BuildingModel> buildings =
        resultBuilding.docs.map((e) => BuildingModel.fromJson(e)).toList();

        // Client-side filtering: Hanya ambil yang statusnya 'Tersedia'
        // Digunakan agar user tidak bisa membooking gedung yang rusak/non-aktif.
        final buildingAvail =
        buildings.where((element) => element.status == "Tersedia").toList();
        return buildingAvail;
      } else {
        statusCode = "200";
        final List<BuildingModel> buildings = [];
        return buildings;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Mengubah status building menjadi tidak tersedia
  changeStatusBuilding(String name) async {
    statusCode = "";
    error = "";
    try {
      // Mencari gedung berdasarkan Nama
      final resultBuilding = await Repositories()
          .db
          .collection("buildings")
          .where("name", isEqualTo: name)
          .get();

      if (resultBuilding.docs.isNotEmpty) {
        final building = resultBuilding.docs.first;
        // Update status field saja
        await Repositories()
            .db
            .collection("buildings")
            .doc(building.id)
            .update({
          "status": "Tidak Tersedia",
        });
        statusCode = "200";
      }
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  ///Menghapus building
  deleteBuilding(String id) async {
    statusCode = "";
    try {
      // Hapus dokumen secara permanen dari Firestore
      await Repositories().db.collection("buildings").doc(id).delete();
      statusCode = "200";
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }
}