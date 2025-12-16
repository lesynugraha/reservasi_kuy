import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/model/history_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/parsing.dart';
import '../../widgets/general/widget_text_content_reservation.dart';
import '../../widgets/general/widget_title_desc_card_view.dart';
import '../../widgets/general/dialog_proof_view.dart'; // <--- Import Dialog

// Widget ini dipisahkan agar kode di HistoryPage lebih bersih.
// Bersifat Stateless karena hanya menerima data (HistoryModel) dan menampilkannya, tidak ada perubahan state internal.
class HistoryCardView extends StatelessWidget {
  const HistoryCardView({
    super.key,
    required this.history,
    required this.function,
    required this.role,
  });

  final HistoryModel history;
  final VoidCallback function;
  final String role;

  // Logic handling gambar gedung.
  // Menggunakan CachedNetworkImage untuk efisiensi: gambar didownload sekali, lalu disimpan di cache lokal.
  // Ini mencegah penggunaan data berlebih saat user scroll list naik-turun.
  imageLoader() {
    if (history.image == "") {
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
            child: CachedNetworkImage(
              height: 100,
              width: 100,
              imageUrl: history.image!,
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
            border: Border.all(width: 1, color: Colors.grey)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  imageLoader(),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextTitleDescriptionCardView(
                          text: history.buildingName!,
                          isTitle: true,
                        ),

                        // Conditional Rendering berdasarkan Role:
                        // Jika Admin (role == "1"), tampilkan nama pemesan agar Admin tahu siapa yang reservasi.
                        // Jika User biasa, tidak perlu ditampilkan (redundant lihat nama sendiri).
                        role == "1"
                            ? TextContentCardView(
                          name: "Pengguna",
                          content: history.contactName!,
                        )
                            : const SizedBox(),

                        TextContentCardView(
                          name: "Mulai",
                          content: ParsingString()
                              .convertDateWithHour(history.dateStart!),
                        ),
                        TextContentCardView(
                          name: "Selesai",
                          content: ParsingString()
                              .convertDateWithHour(history.dateEnd!),
                        ),
                        TextContentCardView(
                          name: "Dibuat",
                          content: ParsingString()
                              .convertDateWithHour(history.dateCreated!),
                        ),
                        TextContentCardView(
                          name: "Diselesaikan",
                          content: history.dateFinished != ""
                              ? ParsingString()
                              .convertDateWithHour(history.dateFinished!)
                              : "Belum Diselesaikan",
                        ),
                        const TextTitleDescriptionCardView(
                          text: "Keterangan",
                        ),
                        TextTitleDescriptionCardView(
                          text: history.information!,
                        ),

                        // Validasi Null Safety untuk Bukti Upload:
                        // Link "Lihat Bukti Upload" hanya muncul jika URL gambar ada dan tidak kosong.
                        // Mencegah error/blank screen jika user belum upload bukti (untuk kasus tertentu).
                        if (history.proofImage != null &&
                            history.proofImage!.isNotEmpty) ...[
                          const Gap(5),
                          InkWell(
                            // Memanggil DialogProofView untuk preview gambar tanpa pindah halaman.
                            onTap: () => DialogProofView.show(
                                context, history.proofImage!),
                            child: const Text(
                              "Lihat Bukti Upload",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        // Menampilkan Catatan Penolakan (jika ada).
                        // Biasanya diisi oleh Admin saat menolak reservasi.
                        if (history.note != null &&
                            history.note!.isNotEmpty) ...[
                          const Gap(5),
                          const TextTitleDescriptionCardView(
                            text: "Alasan Penolakan/Catatan",
                          ),
                          Text(
                            history.note!,
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Badge Status di bagian bawah kartu
              Container(
                height: 35,
                width: 120,
                decoration: _boxDecoration(), // Warna border dinamis
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  child: Center(
                    child: Text(
                      history.status!,
                      style: _textStyle(), // Warna teks dinamis
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Visual Feedback: Mengubah warna border container status.
  // - Biru: Jika status positif (Selesai/Disetujui).
  // - Merah: Jika status negatif/pending (Ditolak/Menunggu).
  _boxDecoration() {
    if (history.status == "Selesai" || history.status == "Disetujui") {
      return BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.blueAccent,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      );
    } else {
      return BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.redAccent,
        ),
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      );
    }
  }

  // Visual Feedback: Mengubah warna teks status agar senada dengan border.
  _textStyle() {
    if (history.status == "Selesai" || history.status == "Disetujui") {
      return GoogleFonts.openSans(
        color: Colors.blueAccent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );
    } else {
      return GoogleFonts.openSans(
        color: Colors.redAccent,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );
    }
  }
}