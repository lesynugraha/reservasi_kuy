import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/data/model/user_model.dart';

import '../../utils/constant/constant.dart';

// Widget kartu (Card View) yang dapat digunakan kembali (Reusable) untuk menampilkan data User dalam bentuk list.
// Biasanya digunakan di halaman Admin untuk memanajemen daftar siswa/user.
class UserCardView extends StatelessWidget {
  const UserCardView({
    super.key,
    required this.user,
    required this.editFunction,
    required this.deleteFunction,
    required this.detailFunction,
  });

  // Data model user yang akan ditampilkan
  final UserModel user;

  // Callback functions: Logika apa yang terjadi saat tombol Edit/Hapus/Detail ditekan
  // tidak ditulis di sini, melainkan dilempar (delegated) ke parent widget yang memanggilnya.
  final VoidCallback editFunction;
  final VoidCallback deleteFunction;
  final VoidCallback detailFunction;

  // Helper function untuk menangani logika foto profil.
  // Menampilkan foto default jika user belum upload, atau foto dari URL jika sudah ada.
  imageLoader() {
    if (user.image == "") {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: ClipOval( // Membuat gambar menjadi lingkaran (Circular Avatar)
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
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            // Menggunakan CachedNetworkImage
            // Fitur ini penting untuk performa list: gambar dicache di memori HP,
            // jadi tidak perlu download ulang setiap kali user scroll list.
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
    return Container(
      height: 130, // Tinggi kartu diset tetap (fixed) agar tampilan list rapi dan seragam
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: Colors.grey, // Border tipis sebagai pemisah visual antar item
        ),
      ),
      child: Column(
        children: [
          // Bagian Atas: Informasi User + Tombol Detail (Panah)
          Expanded(
            child: Row(
              children: [
                imageLoader(), // Panggil helper gambar
                const Gap(10),
                // Informasi Teks (Nama & Username)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName!,
                          maxLines: 2, // Batasi 2 baris agar layout tidak rusak
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
                // Tombol Panah Kanan (Menuju Detail)
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

          // Garis pemisah horizontal
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
                      onTap: editFunction, // Memanggil fungsi edit dari parent
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
                      onTap: deleteFunction, // Memanggil fungsi delete dari parent
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
    );
  }
}