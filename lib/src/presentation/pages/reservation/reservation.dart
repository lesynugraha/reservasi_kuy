import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/presentation/widgets/general/pop_up.dart';

import '../../../data/bloc/reservation/reservation_bloc.dart';
import '../../../data/bloc/reservation_building/reservation_building_bloc.dart';
import '../../../data/model/building_model.dart';
import '../../utils/general/parsing.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_pages.dart';
import '../../widgets/general/widget_custom_loading.dart';
import 'building_available_card_view.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  late TextEditingController dateStartController;
  late TextEditingController dateEndController;
  late DateTimeRange selectedTimeRange;
  late ReservationBuildingBloc reservationBuildingBloc;
  late ReservationBloc reservationBloc;
  late BuildingModel building;

  /// Fungsi Inti: Memilih Rentang Tanggal (Date Range Picker).
  /// Saya menggunakan widget bawaan Flutter 'showDateRangePicker' karena UX-nya intuitif
  /// untuk memilih tanggal mulai dan selesai dalam satu dialog.
  pickRangeDate(BuildContext context) async {
    final DateTimeRange? dateTimeRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(), // Tidak boleh pilih tanggal lampau
      lastDate: DateTime(DateTime.now().year + 2), // Batas maksimal 2 tahun ke depan
      helpText: "Pilih tanggal",
      saveText: "Simpan",
    );

    // Jika user jadi memilih tanggal (tidak cancel):
    if (dateTimeRange != null) {
      setState(() {
        selectedTimeRange = dateTimeRange;
        // Simpan tanggal ke controller untuk dikirim ke backend nanti
        dateStartController =
            TextEditingController(text: selectedTimeRange.start.toString());
        dateEndController =
            TextEditingController(text: selectedTimeRange.end.toString());
      });
      // Otomatis cari gedung yang tersedia di tanggal tersebut setelah memilih.
      getBuildingAvail();
    }
  }

  /// Trigger event ke Bloc untuk mendapatkan daftar gedung.
  /// (Catatan: Logic filter ketersediaan sebenarnya ada di sisi Backend/Query,
  /// di sini kita request data gedung dulu).
  getBuildingAvail() {
    reservationBuildingBloc = context.read<ReservationBuildingBloc>();
    reservationBuildingBloc.add(GetBuildingAvail());
  }

  /// Validasi Akhir: Cek spesifik apakah gedung X kosong di tanggal Y.
  /// Fungsi ini dipanggil SAAT user menekan tombol "Reservasi" di salah satu gedung.
  /// Tujuannya untuk memastikan tidak ada "Race Condition" (keduluan orang lain booking di detik yang sama).
  getReservationAvail(String dateStart, String dateEnd, String buildingName) {
    reservationBloc = context.read<ReservationBloc>();
    reservationBloc.add(GetReservationCheck(dateStart, dateEnd, buildingName));
  }

  /// Reset/Inisialisasi data gedung saat halaman pertama dibuka.
  buildingAvailInitial() {
    reservationBuildingBloc = context.read<ReservationBuildingBloc>();
    reservationBuildingBloc.add(InitialBuildingAvail());
  }

  @override
  void initState() {
    // Default range tanggal adalah hari ini
    selectedTimeRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now(),
    );
    buildingAvailInitial();
    dateStartController = TextEditingController();
    dateEndController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    dateStartController.dispose();
    dateEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener khusus untuk mendengarkan hasil pengecekan ketersediaan (GetReservationCheck).
    return BlocListener<ReservationBloc, ReservationState>(
      listener: (context, state) {
        // KASUS 1: Gedung SUDAH DIBOOKING orang lain.
        if (state is ReservationBooked) {
          if (state.booked.isNotEmpty) {
            // Tampilkan popup info siapa yang meminjam, supaya transparan.
            PopUp().whenSuccessDoSomething(
              context,
              "Dipakai oleh ${state.booked.first.contactName}\nMulai: ${ParsingString().convertDate(state.booked.first.dateStart!)}\nSelesai: ${ParsingString().convertDate(state.booked.first.dateEnd!)}",
              Icons.person,
            );
          }
          // KASUS 2: Gedung AMAN/KOSONG.
        } else if (state is ReservationNoBooked) {
          // Tampilkan konfirmasi untuk lanjut ke halaman form data diri (ConfirmReservation).
          PopUp().whenDoSomething(
            context,
            "Bisa melakukan reservasi. Reservasi sekarang?",
            Icons.corporate_fare,
                () {
              return context.pushNamed(
                Routes().confirmReservation,
                extra: building, // Bawa objek gedung yang dipilih
                queryParameters: {
                  "dateStart": dateStartController.text.toString(), // Bawa tanggal mulai
                  "dateEnd": dateEndController.text.toString(),     // Bawa tanggal selesai
                },
              );
            },
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderPage(
                  name: "Reservasi",
                ),
                Expanded(
                  child: RefreshIndicator(
                    // Fitur Reset: Tarik layar untuk menghapus filter tanggal dan reset list gedung.
                    onRefresh: () async {
                      if (dateStartController.text.isNotEmpty &&
                          dateEndController.text.isNotEmpty) {
                        setState(() {
                          dateStartController.clear();
                          dateEndController.clear();
                        });
                      }
                      buildingAvailInitial();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Area Filter Tanggal (Box Border Hitam)
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.black,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: IntrinsicHeight(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Pilih tanggal reservasi",
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const Gap(10),
                                      // Widget Custom untuk menampilkan tanggal yang dipilih / tombol pilih tanggal
                                      selectedDateRange(),
                                      const Divider(
                                        height: 1,
                                        color: Colors.black,
                                        thickness: 1,
                                      ),
                                      const Gap(30),
                                      // Tombol Cari (Disable jika tanggal belum dipilih)
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ButtonPositive(
                                          name: "Cari Gedung",
                                          function: buttonSearch(),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Gap(18),
                            // List Gedung yang tersedia (Hasil dari Bloc)
                            BlocBuilder<ReservationBuildingBloc,
                                ReservationBuildingState>(
                              builder: (context, state) {
                                if (state is ResBuGetSuccess) {
                                  final buildings = state.buildings;
                                  // Sorting nama gedung A-Z agar mudah dicari
                                  buildings.sort((a, b) => a.name!.compareTo(b.name!));

                                  if (buildings.isNotEmpty) {
                                    return Column(
                                      children: [
                                        Text(
                                          "Gedung yang tersedia",
                                          style: GoogleFonts.openSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        ListView.builder(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                            bottom: 30,
                                          ),
                                          itemCount: buildings.length,
                                          shrinkWrap: true,
                                          physics:
                                          const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 8),
                                              child: BuildingAvailableCardView(
                                                building: buildings[index],
                                                // Saat tombol 'Reservasi' diklik:
                                                function: () {
                                                  building = buildings[index];
                                                  // Cek ketersediaan lagi (Double Check)
                                                  getReservationAvail(
                                                    dateStartController.text,
                                                    dateEndController.text,
                                                    buildings[index].name!,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Empty State
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          "Tidak ada gedung/ruang yang tersedia",
                                          style: GoogleFonts.openSans(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  return const SizedBox();
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            // Loading Overlay saat cek ketersediaan
            Center(
              child: BlocBuilder<ReservationBuildingBloc,
                  ReservationBuildingState>(
                builder: (context, state) {
                  if (state is ResBuLoading) {
                    return const CustomLoading();
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // Logic Tombol Cari:
  // Tombol tidak bisa diklik (return fungsi kosong) jika tanggal belum dipilih lengkap.
  // Ini mencegah user mencari tanpa filter tanggal.
  buttonSearch() {
    if (dateStartController.text.isEmpty || dateEndController.text.isEmpty) {
      return () {};
    } else {
      return () {
        getBuildingAvail();
      };
    }
  }

  // Widget Tampilan Tanggal yang Dipilih.
  // Mengubah tampilan secara dinamis:
  // 1. Jika sudah pilih -> Tampilkan rentang tanggal + durasi hari + tombol reset (X).
  // 2. Jika belum pilih -> Tampilkan teks "Pilih tanggal reservasi".
  selectedDateRange() {
    if (dateStartController.text.isNotEmpty &&
        dateEndController.text.isNotEmpty) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(
                    8,
                  ),
                  child: InkWell(
                    onTap: () {
                      pickRangeDate(context); // Bisa ubah tanggal lagi
                    },
                    child: const Icon(
                      Icons.date_range,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        // Format tampilan tanggal agar mudah dibaca user
                        "${ParsingString().convertDate(
                          dateStartController.text,
                        )} - ${ParsingString().convertDate(
                          dateEndController.text,
                        )}",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Tombol Reset (X) untuk menghapus filter tanggal
                    Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              dateStartController.clear();
                              dateEndController.clear();
                              buildingAvailInitial(); // Reset list gedung ke kondisi awal
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Baris kedua: Menampilkan durasi (Total Hari)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(
                    8,
                  ),
                  child: InkWell(
                    onTap: () {
                      pickRangeDate(context);
                    },
                    child: const Icon(
                      Icons.date_range,
                      size: 30,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${(selectedTimeRange.duration.inDays.toInt() + 1)} Hari",
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Tampilan Default (Belum pilih tanggal)
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  pickRangeDate(context);
                },
                child: const Icon(
                  Icons.date_range,
                  size: 30,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "Pilih tanggal reservasi",
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
  }
}