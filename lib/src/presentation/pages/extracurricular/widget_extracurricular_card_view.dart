import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/data/model/extracurricular_model.dart';
import 'package:reservation_app/src/presentation/utils/constant/constant.dart';

// Widget kartu (Card) untuk menampilkan item ekstrakurikuler di halaman list utama.
// Dibuat reusable (bisa dipakai berulang) dan stateless karena data dikontrol oleh parent.
class ExtracurricularCardView extends StatelessWidget {
  const ExtracurricularCardView({
    super.key,
    required this.excur,
    required this.editFunction,
    required this.deleteFunction,
    required this.detailFunction,
    required this.role,
  });

  final ExtracurricularModel excur;

  // Callback functions untuk meneruskan aksi tap ke parent widget.
  // Ini menjaga agar logic navigasi/hapus tetap terpusat di Page, bukan di Widget kecil ini.
  final VoidCallback editFunction;
  final VoidCallback deleteFunction;
  final VoidCallback detailFunction;

  // Variabel role untuk menentukan apakah tombol Edit/Hapus perlu ditampilkan atau tidak.
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Tinggi kartu dinamis:
      // Jika Admin (role == "1") -> 140 (butuh space untuk tombol aksi).
      // Jika User -> 110 (cukup info saja).
      height: role == "1" ? 140 : 110,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: Colors.grey,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageLoader(), // Memanggil helper untuk load gambar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          excur.name!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis, // Potong teks jika terlalu panjang
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          excur.schedule!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tombol Panah Detail
                SizedBox(
                  height: double.maxFinite,
                  child: Material(
                    color: Colors.transparent,
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
          // Bagian bawah kartu yang berisi tombol Edit & Delete (Khusus Admin)
          adminBehavior(role),
        ],
      ),
    );
  }

  // Fungsi helper untuk manajemen gambar.
  // 1. Cek apakah ada URL gambar.
  // 2. Jika ada, gunakan CachedNetworkImage untuk efisiensi bandwidth & memori.
  // 3. Jika tidak, tampilkan gambar default (placeholder).
  imageLoader() {
    if (excur.image == "") {
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
              imageUrl: excur.image!,
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

  // Logika tampilan berdasarkan Role.
  // Hanya merender tombol aksi (Edit & Delete) jika user adalah SuperAdmin ("1").
  // Jika bukan, return SizedBox() agar tidak memakan tempat di layout.
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
                // Tombol Edit
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: editFunction,
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
                // Tombol Delete
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: deleteFunction,
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
      return const SizedBox();
    }
  }
}