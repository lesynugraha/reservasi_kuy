import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/data/model/extracurricular_model.dart';

// Widget kartu (Card View) khusus untuk mode manajemen (Edit/Hapus).
// Bersifat presentasional (Stateless), hanya menerima data dan callback aksi dari parent.
class EditExtracurricularCardView extends StatelessWidget {
  const EditExtracurricularCardView({
    super.key,
    required this.excur,
    required this.functionEdit,
    required this.functionDelete,
  });

  // Model data ekstrakurikuler yang akan ditampilkan.
  final ExtracurricularModel excur;

  // Callback function untuk menangani aksi Edit dan Delete.
  // Logika bisnis tidak ditulis di sini, melainkan didelegasikan ke parent widget (AddExtracurricularPage).
  final VoidCallback functionEdit;
  final VoidCallback functionDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Styling container dengan border tipis untuk membedakan antar item di list.
      decoration: BoxDecoration(
        border: Border.all(width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Menggunakan Expanded pada widget Text.
          // Tujuannya agar teks mengambil sisa ruang yang tersedia di sebelah kiri tombol aksi,
          // mencegah error overflow jika nama ekskul terlalu panjang.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                excur.name!,
                style: GoogleFonts.openSans(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 3, // Membatasi maksimal 3 baris
                overflow: TextOverflow.ellipsis, // Menambahkan '...' jika teks terpotong
              ),
            ),
          ),

          // Tombol Aksi: Edit
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            // Menggunakan Material + InkWell untuk efek visual (ripple) saat ditekan.
            // Penting untuk UX agar user tahu tombol merespons sentuhan.
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: functionEdit, // Memicu callback edit
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit),
                ),
              ),
            ),
          ),

          // Tombol Aksi: Delete
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: functionDelete, // Memicu callback delete
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}