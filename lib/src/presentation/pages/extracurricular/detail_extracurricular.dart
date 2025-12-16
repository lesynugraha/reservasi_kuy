import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/data/model/extracurricular_model.dart';

import '../../utils/constant/constant.dart';
import '../../widgets/general/header_detail_page.dart';

// Halaman detail ini dibuat Stateless karena fungsinya hanya menampilkan data (Read-Only).
// Tidak ada perubahan state atau interaksi user yang mengubah tampilan secara dinamis di sini.
class DetailExtracurricularPage extends StatelessWidget {

  // Constructor menerima objek 'ExtracurricularModel' secara utuh dari halaman sebelumnya (List Page).
  // Teknik ini disebut 'Data Passing'. Keuntungannya: Tidak perlu request API/Firebase ulang berdasarkan ID,
  // sehingga aplikasi lebih cepat dan hemat request database (Cost Efficiency).
  const DetailExtracurricularPage({
    super.key,
    required this.extracurricular,
  });

  final ExtracurricularModel extracurricular;

  // Helper function untuk manajemen tampilan gambar.
  // Memisahkan logika UI gambar supaya kode di dalam build() lebih bersih.
  imageLoader() {
    // Logic 1: Jika URL gambar kosong (user tidak upload), tampilkan asset default.
    if (extracurricular.image! == "") {
      return const Image(
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage(assetsDefaultBuildingImage),
      );
    } else {
      // Logic 2: Jika ada URL, gunakan CachedNetworkImage.
      // Ini penting untuk performa: Gambar disimpan di cache HP setelah download pertama.
      // Jika user buka halaman ini lagi, gambar load instan tanpa internet.
      return CachedNetworkImage(
        height: 250,
        width: double.infinity,
        imageUrl: extracurricular.image!,
        // Tampilan sementara saat loading gambar
        placeholder: (context, url) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        // Fallback jika gambar gagal diload (misal link rusak)
        errorWidget: (context, url, error) {
          return const Image(
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            image: AssetImage(assetsDefaultBuildingImage),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Menggunakan widget header yang reusable agar konsisten dengan halaman detail lainnya.
          HeaderDetailPage(
            pageName: extracurricular.name!,
          ),
          Expanded(
            child: RefreshIndicator(
              // RefreshIndicator tetap dipasang untuk menjaga UX standar Android (bisa ditarik),
              // meskipun di sini kosong karena datanya sudah dibawa dari halaman sebelumnya.
              onRefresh: () async {},
              child: SingleChildScrollView(
                // Physics AlwaysScrollable diperlukan agar user tetap bisa scroll (bounciness)
                // meskipun kontennya sedikit, supaya UX terasa fluid.
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(15),
                    imageLoader(), // Memanggil fungsi gambar
                    const Gap(15),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Detail Nama Ekskul
                          Text(
                            extracurricular.name!,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // Detail Deskripsi
                          Text(
                            extracurricular.description!,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(10),
                          // Detail Jadwal
                          Text(
                            "Jadwal",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            extracurricular.schedule!,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const Gap(10),
                          // Detail Instansi (Penyelenggara)
                          Text(
                            "Instansi",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            extracurricular.agency!,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(60), // Space tambahan di bawah agar konten tidak tertutup navbar (jika ada)
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}