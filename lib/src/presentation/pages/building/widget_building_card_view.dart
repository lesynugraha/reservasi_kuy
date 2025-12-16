import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/model/building_model.dart';
import '../../utils/constant/constant.dart';

// Widget ini dibuat Stateless karena hanya bertugas menampilkan data (Presentational Widget).
// Tidak ada perubahan state internal di sini, semua data dan fungsi dilempar dari parent (BuildingPage).
class BuildingCardView extends StatelessWidget {
  const BuildingCardView({
    super.key,
    required this.building,
    required this.detailFunction,
    required this.editFunction,
    required this.deleteFunction,
    required this.role,
  });

  final BuildingModel building;
  // Menggunakan callback (VoidCallback) agar logika navigasi dan penghapusan tetap berada di parent widget.
  // Ini menerapkan prinsip 'Separation of Concerns', jadi widget ini murni untuk UI saja.
  final VoidCallback detailFunction;
  final VoidCallback editFunction;
  final VoidCallback deleteFunction;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Tinggi container dibuat dinamis.
      // Jika user adalah SuperAdmin (role == "1"), tinggi 140 agar muat tombol Edit/Hapus di bawah.
      // Jika User biasa, cukup 110.
      height: role == "1" ? 140 : 110,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageLoader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          building.name!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis, // Potong teks jika kepanjangan
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Kapasitas: ${building.capacity}",
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Status: ${building.status}",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tombol panah detail (Chevron)
                SizedBox(
                  height: double.maxFinite,
                  child: Material(
                    color: Colors.transparent,
                    // Menggunakan InkWell untuk memberikan efek visual 'ripple' saat ditekan (UX Feedback).
                    child: InkWell(
                      onTap: detailFunction,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bagian tombol aksi Admin (Edit & Delete) yang dipisahkan ke fungsi sendiri.
          adminBehavior(role),
        ],
      ),
    );
  }

  // Fungsi helper untuk menangani logika tampilan gambar:
  // 1. Gambar kosong -> Tampilkan default asset.
  // 2. Gambar ada -> Gunakan CachedNetworkImage untuk efisiensi memori & kuota.
  imageLoader() {
    if (building.image == "") {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const Image(
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              image: AssetImage(assetsDefaultBuildingImage),
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              height: 80,
              width: 80,
              imageUrl: building.image!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorWidget: (context, url, error) {
                return const Image(
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  image: AssetImage(assetsDefaultBuildingImage),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  // Logika kontrol akses UI (Role-Based UI).
  // Tombol Edit dan Hapus hanya dirender jika role user adalah "1" (SuperAdmin).
  // User biasa tidak akan melihat tombol ini sama sekali (return SizedBox/Kosong).
  adminBehavior(String role) {
    if (role == "1") {
      return Column(
        children: [
          const Divider(
            thickness: 0.5,
            height: 1,
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: editFunction, // Callback edit dipanggil
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: deleteFunction, // Callback delete dipanggil
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.delete,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      );
    } else {
      // Jika bukan admin, render kotak kosong agar layout tidak berantakan.
      return const SizedBox();
    }
  }
}