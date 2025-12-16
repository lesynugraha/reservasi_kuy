import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/model/building_model.dart';

// Widget ini dipisahkan menjadi komponen sendiri (StatelessWidget) untuk digunakan pada list manajemen gedung.
// Fokus utamanya adalah menampilkan informasi ringkas (nama) dan menyediakan akses cepat ke fungsi Edit dan Delete.
class EditBuildingCardView extends StatelessWidget {
  const EditBuildingCardView({
    super.key,
    required this.building,
    required this.functionEdit,
    required this.functionDelete,
  });

  // Menerima data model gedung untuk ditampilkan.
  final BuildingModel building;

  // Menggunakan tipe data VoidCallback? (nullable) agar fleksibel.
  // Fungsi logika (apa yang terjadi saat tombol ditekan) didefinisikan di parent widget,
  // sehingga widget ini murni bersifat presentasional (UI only).
  final VoidCallback? functionEdit;
  final VoidCallback? functionDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1), // Memberikan border tipis untuk pemisah antar item visual
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Menggunakan Expanded pada bagian Text agar teks mengambil sisa ruang yang tersedia.
          // Ini mencegah error 'RenderFlex overflow' jika nama gedung sangat panjang.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                building.name!,
                style: GoogleFonts.openSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 3, // Membatasi teks maksimal 3 baris agar tinggi kartu tetap terjaga
                overflow: TextOverflow.ellipsis, // Menambahkan '...' jika teks melebihi 3 baris
              ),
            ),
          ),

          // Tombol Edit
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            // Material widget diperlukan di sini sebagai leluhur InkWell
            // agar efek riak air (ripple effect) saat diklik terlihat jelas (feedback UX).
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: functionEdit, // Memanggil callback edit dari parent
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit),
                ),
              ),
            ),
          ),

          // Tombol Delete
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: functionDelete, // Memanggil callback delete dari parent
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