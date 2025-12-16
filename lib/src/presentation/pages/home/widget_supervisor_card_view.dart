import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/data/model/user_model.dart';

import '../../utils/constant/constant.dart';

// Widget kartu khusus untuk menampilkan daftar akun Supervisor (Admin Sekolah).
// Hanya muncul di halaman Home milik SuperAdmin.
// Saya pisahkan jadi widget sendiri supaya kode di HomePage tidak terlalu panjang dan ruwet.
class SupervisorCardView extends StatelessWidget {
  const SupervisorCardView({
    super.key,
    required this.user,
    required this.editFunction,
    required this.deleteFunction,
    required this.detailFunction,
  });

  final UserModel user;

  // Callback untuk aksi-aksi yang bisa dilakukan SuperAdmin terhadap akun Supervisor.
  // Logic eksekusinya tetap di parent (HomePage), widget ini cuma pemicu (Trigger).
  final VoidCallback editFunction;
  final VoidCallback deleteFunction;
  final VoidCallback detailFunction;

  // Helper function untuk menampilkan foto profil.
  // Menggunakan 'ClipOval' agar fotonya berbentuk bulat (Circular Avatar), standar UI profile modern.
  imageLoader() {
    if (user.image == "") {
      // Tampilkan placeholder jika user belum pasang foto profil
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image(
              height: 70,
              width: 70,
              fit: BoxFit.cover,
              image: AssetImage(assetsDefaultProfilePicture),
            ),
          ),
        ),
      );
    } else {
      // Tampilkan foto dari database menggunakan CachedNetworkImage
      // supaya hemat kuota dan loading lebih cepat saat discroll ulang.
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: CachedNetworkImage(
              height: 70,
              width: 70,
              imageUrl: user.image!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorWidget: (context, url, error) {
                return const Image(
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
                  image: AssetImage(assetsDefaultProfilePicture),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 130, // Tinggi fixed agar tampilan list rapi
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white, // Background putih agar kontras dengan warna biru di Home SuperAdmin
        ),
        child: Column(
          children: [
            // Bagian Atas: Info Supervisor (Foto, Nama Instansi, Username)
            Expanded(
              child: Row(
                children: [
                  imageLoader(),
                  const Gap(10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.agency!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            user.username!,
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

            // Garis Pembatas antara Info dan Tombol Aksi
            const Divider(
              thickness: 0.5,
              height: 1,
            ),

            // Bagian Bawah: Tombol Aksi (Edit & Hapus)
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
                  // Tombol Hapus
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
        ),
      ),
    );
  }
}