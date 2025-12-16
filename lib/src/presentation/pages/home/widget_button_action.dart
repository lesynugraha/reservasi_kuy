import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Widget ini dibuat 'Reusable' (Dapat digunakan kembali).
// Tujuannya agar tidak perlu membuat kodingan tombol yang sama berulang-ulang di halaman Home.
// Cukup panggil 'ButtonAction', lalu kirim parameter teks dan fungsinya.
class ButtonAction extends StatelessWidget {
  const ButtonAction({
    super.key,
    required this.name, // Teks tombol (Contoh: "Terima", "Tolak", "Selesai")
    required this.function, // Logika/Fungsi yang akan dijalankan saat tombol ditekan
  });

  final String name;
  final VoidCallback function;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, // Lebar fixed agar ukuran tombol konsisten
      // Menggunakan fungsi helper decorationBox() untuk menentukan warna border secara dinamis
      decoration: decorationBox(),
      // Material widget diperlukan agar efek 'InkWell' (ripple/percikan air) terlihat jelas
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: function, // Menjalankan fungsi yang dikirim dari parent widget
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Center(
              child: Text(
                name,
                // Menggunakan helper decorationText() agar warna teks sinkron dengan warna border
                style: decorationText(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Logika Conditional Styling untuk Border:
  // - Jika aksi bersifat POSITIF (Terima/Selesai) -> Warna BIRU.
  // - Jika aksi bersifat NEGATIF (Tolak/Batal) -> Warna MERAH.
  // Ini memudahkan user membedakan tindakan secara visual (UX visual cue).
  decorationBox() {
    if (name == "Terima" || name == "Selesai") {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: Colors.blueAccent,
        ),
      );
    } else {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: Colors.redAccent,
        ),
      );
    }
  }

  // Logika Conditional Styling untuk Teks:
  // Warna teks menyesuaikan dengan border agar desain konsisten.
  decorationText() {
    if (name == "Terima" || name == "Selesai") {
      return GoogleFonts.openSans(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      );
    } else {
      return GoogleFonts.openSans(
        color: Colors.redAccent,
        fontWeight: FontWeight.bold,
      );
    }
  }
}