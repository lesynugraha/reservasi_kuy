import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/model/building_model.dart';
import '../../utils/constant/constant.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/widget_title_subtitle.dart';

class DetailBuilding extends StatelessWidget {
  // Constructor ini menerima data objek 'BuildingModel' yang dikirim dari halaman sebelumnya.
  // Jadi saya tidak perlu request ke API/Firebase lagi di sini, cukup tampilkan data yang sudah ada (efisiensi bandwidth).
  const DetailBuilding({super.key, required this.building});

  final BuildingModel building;

  // Fungsi helper untuk menghandle logika tampilan gambar.
  // Saya memisahkan fungsi ini agar metode build() utama tidak terlalu panjang dan ruwet.
  imageLoader() {
    // Cek 1: Jika URL gambar kosong (user tidak upload), tampilkan gambar default dari assets.
    if (building.image! == "") {
      return const Image(
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage(assetsDefaultBuildingImage),
      );
    } else {
      // Cek 2: Jika ada URL, gunakan CachedNetworkImage.
      // Ini penting buat performa, Pak. Jadi gambar yang pernah didownload akan disimpan di cache HP.
      // Kalau user buka halaman ini lagi, tidak perlu download ulang (hemat kuota user & server).
      return CachedNetworkImage(
        height: 250,
        width: double.infinity,
        imageUrl: building.image!,
        // Tampilan loading saat gambar sedang didownload
        placeholder: (context, url) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        // Error handling: Jika URL rusak atau gagal load, fallback ke gambar default assets
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
          // Header custom yang sudah saya buat reusable
          HeaderDetailPage(
            pageName: building.name!,
          ),
          Expanded(
            child: RefreshIndicator(
              // RefreshIndicator tetap saya pasang untuk konsistensi UX (user bisa tarik layarnya),
              // meskipun saat ini belum ada fungsi reload data khusus di halaman detail ini.
              onRefresh: () async {},
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(10),
                    // Memanggil fungsi loader gambar yang tadi dibuat
                    imageLoader(),
                    const Gap(15),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menggunakan widget custom 'TitleSubtitleDetailPage' untuk menampilkan info teks.
                          // Ini supaya kodenya modular dan rapi, tidak perlu ketik ulang style Text untuk setiap item.
                          TitleSubtitleDetailPage(
                            title: building.name!,
                            subtitle: building.description!,
                            isTitle: true,
                          ),
                          TitleSubtitleDetailPage(
                            title: "Fasilitas",
                            subtitle: building.facility!,
                          ),
                          TitleSubtitleDetailPage(
                            title: "Kapasitas",
                            subtitle: "${building.capacity!.toString()} Orang",
                          ),
                          TitleSubtitleDetailPage(
                            title: "Peraturan",
                            subtitle: building.rule!,
                          ),
                          TitleSubtitleDetailPage(
                            title: "Status Gedung/Ruangan",
                            subtitle: building.status!,
                          ),
                        ],
                      ),
                    ),
                    const Gap(60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}