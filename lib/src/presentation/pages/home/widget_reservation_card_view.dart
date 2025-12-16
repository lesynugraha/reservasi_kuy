import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/model/reservation_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/parsing.dart';
import '../../widgets/general/widget_title_desc_card_view.dart';
import '../../widgets/general/widget_text_content_reservation.dart';
import '../../widgets/general/dialog_proof_view.dart';
import '../../utils/routes/route_name.dart'; // Import Routes
import 'widget_button_action.dart';

// Widget ini memisahkan tampilan kartu reservasi dari logic utama di HomePage.
// Tujuannya agar kode lebih modular dan mudah dimaintain (Separation of Concerns).
class ReservationCardView extends StatelessWidget {
  const ReservationCardView({
    super.key,
    required this.reservation,
    this.acceptFunction,
    this.declineFunction,
    this.doneFunction,
    this.cancelFunction,
    this.deleteFunction,
    required this.role,
  });

  final ReservationModel reservation;
  // Callback functions bersifat nullable (?) karena tidak semua fungsi dipakai oleh setiap Role.
  // Contoh: Admin tidak butuh 'cancelFunction', User tidak butuh 'acceptFunction'.
  final VoidCallback? acceptFunction;
  final VoidCallback? declineFunction;
  final VoidCallback? doneFunction;
  final VoidCallback? cancelFunction;
  final VoidCallback? deleteFunction;
  final String role;

  // Helper untuk manajemen gambar (Default vs Network Cached)
  imageLoader() {
    if (reservation.image == "") {
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
            child: CachedNetworkImage( //
              height: 100,
              width: 100,
              imageUrl: reservation.image!,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageLoader(),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextTitleDescriptionCardView(
                          text: reservation.buildingName!,
                          isTitle: true,
                        ),

                        // Logic Tampilan Conditional:
                        // Hanya Admin (Role 1) yang perlu melihat nama pemesan ("Pengguna").
                        // Bagi User (Role 2), informasi ini ridan (karena itu nama dia sendiri).
                        role == "1"
                            ? TextContentCardView(
                          name: "Pengguna",
                          content: reservation.contactName!,
                        )
                            : const SizedBox(),

                        TextContentCardView(
                          name: "Mulai",
                          content: ParsingString()
                              .convertDateWithHour(reservation.dateStart!),
                        ),
                        TextContentCardView(
                          name: "Selesai",
                          content: ParsingString()
                              .convertDateWithHour(reservation.dateEnd!),
                        ),
                        TextContentCardView(
                          name: "Status",
                          content: reservation.status!,
                        ),
                        const TextTitleDescriptionCardView(
                          text: "Keterangan",
                        ),
                        TextTitleDescriptionCardView(
                          text: reservation.information!,
                        ),

                        // Validasi Bukti Gambar (Proof Image):
                        // Tombol "Lihat Bukti" hanya dirender jika URL bukti TIDAK null dan TIDAK kosong.
                        if (reservation.proofImage != null &&
                            reservation.proofImage!.isNotEmpty) ...[
                          const Gap(8),
                          InkWell(
                            onTap: () {
                              // Memanggil dialog preview gambar tanpa pindah halaman
                              DialogProofView.show(
                                  context, reservation.proofImage!);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility,
                                      size: 16, color: Colors.blue),
                                  Gap(5),
                                  Text(
                                    "Lihat Bukti Pengajuan",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Gap(10),
                      ],
                    ),
                  ),
                ],
              ),
              // Render tombol aksi secara dinamis sesuai Role
              buttonByRole(context),
            ],
          ),
        ),
      ),
    );
  }

  // Logic Penentuan Tombol Aksi:
  // Fungsi ini menentukan tombol apa yang muncul berdasarkan Role User dan Status Reservasi saat ini.
  buttonByRole(BuildContext context) {
    if (role == "1") {
      // === VIEW ADMIN ===
      // Admin selalu melihat tombol Terima/Tolak untuk reservasi yang statusnya "Menunggu".
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ButtonAction(
            name: "Tolak",
            function: declineFunction ?? () {},
          ),
          const Gap(10),
          ButtonAction(
            name: "Terima",
            function: acceptFunction ?? () {},
          ),
        ],
      );
    } else if (role == "2") {
      // === VIEW USER ===
      return Align(
        alignment: Alignment.bottomRight,
        child: Builder(
          builder: (ctx) {
            // Skenario 1: Masih Menunggu -> Bisa Batal
            if (reservation.status == "Menunggu") {
              return ButtonAction(
                name: "Batal",
                function: cancelFunction ?? () {},
              );
              // Skenario 2: Disetujui -> Bisa Selesaikan (Mark as Done)
            } else if (reservation.status == "Disetujui") {
              return ButtonAction(
                name: "Selesai",
                function: doneFunction ?? () {},
              );
              // Skenario 3: Ditolak
            } else if (reservation.status == "Ditolak") {
              // Di sini saya ubah flow-nya.
              // Tombol ini berfungsi ganda:
              // 1. Membersihkan notifikasi/data di Home (via deleteFunction).
              // 2. Mengarahkan user ke halaman History untuk melihat ALASAN penolakan.
              return ButtonAction(
                name: "Reservasi telah tervalidasi",
                function: () {
                  if (deleteFunction != null) {
                    deleteFunction!();
                  }
                  // Navigasi paksa ke History setelah user menekan tombol ini.
                  Navigator.pushNamed(context, Routes().history);
                },
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}