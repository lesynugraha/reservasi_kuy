import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/presentation/widgets/general/button_positive.dart';

import '../../../data/model/building_model.dart';
import '../../utils/constant/constant.dart';

// Widget Item List yang menampilkan gedung yang TERSEDIA (Available) untuk direservasi.
// Memisahkan UI item dari logic halaman utama (ReservationPage) agar kode lebih modular.
class BuildingAvailableCardView extends StatelessWidget {
  const BuildingAvailableCardView({
    super.key,
    required this.function,
    required this.building,
  });

  final BuildingModel building;

  // Callback fungsi yang akan dieksekusi saat tombol "Reservasi" ditekan.
  // Logika reservasi (pindah halaman/submit data) tetap berada di parent widget.
  final VoidCallback function;

  // Helper untuk manajemen gambar (Network vs Asset).
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
              height: 100,
              width: 100,
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
            // Menggunakan CachedNetworkImage untuk optimasi performa list.
            child: CachedNetworkImage(
              height: 100,
              width: 100,
              imageUrl: building.image!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorWidget: (context, url, error) {
                return const Image(
                  height: 100,
                  width: 100,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: Colors.grey,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      // IntrinsicHeight sangat penting di sini.
      // Gunanya agar tinggi widget 'Row' (gambar + teks) dan widget 'Column' di dalamnya
      // menyesuaikan dengan anak yang paling tinggi. Tanpa ini, layout bisa error atau tidak presisi.
      child: IntrinsicHeight(
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageLoader(),
                  // Expanded memastikan kolom teks mengambil sisa lebar yang tersedia di sebelah gambar.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            building.name!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                          Text(
                            "Keterangan: ${building.description}",
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
                ],
              ),
            ),
            // Tombol Reservasi di bagian bawah kartu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ButtonPositive(
                  name: "Reservasi",
                  function: function, // Memicu callback navigasi ke halaman konfirmasi
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}