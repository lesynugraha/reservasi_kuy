import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/bloc/history/history_bloc.dart';
import '../../../data/model/history_model.dart';
import '../../utils/general/parsing.dart';
import '../../widgets/general/header_pages.dart';
import '../../widgets/general/widget_custom_loading.dart';
import 'widget_history_card_view.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late HistoryBloc _historyBloc;
  late String userRole;

  // Variabel state untuk menyimpan filter yang dipilih user (Default: Semua).
  String titleFilter = "Semua Laporan";
  // Variabel untuk menyimpan bulan yang dipilih dari MonthPicker.
  DateTime? selectedDate;

  /// Fetch data untuk Role User (Siswa/Organisasi):
  /// Hanya mengambil data riwayat reservasi milik user itu sendiri.
  _getHistory() {
    _historyBloc = context.read<HistoryBloc>();
    _historyBloc.add(GetHistoryUser());
  }

  /// Fetch data untuk Role Admin (Sekolah):
  /// Mengambil SEMUA laporan reservasi dari seluruh user untuk keperluan monitoring.
  _getReport() {
    _historyBloc = context.read<HistoryBloc>();
    _historyBloc.add(GetReportAdmin());
  }

  /// Logika pembagian fungsi fetch data berdasarkan Role yang login.
  /// Memastikan User tidak bisa intip data Admin, dan sebaliknya Admin bisa lihat semua.
  getHistoryReport() {
    if (userRole == "1") { // Role 1 = Admin/Supervisor
      return _getReport();
    } else if (userRole == "2") { // Role 2 = User
      return _getHistory();
    } else {
      return () {};
    }
  }

  /// Mengambil Role dari SharedPreferences (Local Storage) untuk penyesuaian UI.
  getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userRole = prefs.getString("role")!;
    setState(() {
      userRole = userRole;
    });
  }

  @override
  void didChangeDependencies() {
    // Inisialisasi awal saat halaman dibuka
    userRole = "";
    getRole();
    selectedDate = DateTime.now(); // Default tanggal filter adalah hari ini
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Memanggil fungsi fetch data setiap kali build (bisa dioptimasi ke initState/didChangeDependencies sebenarnya)
    getHistoryReport();
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Column(
              children: [
                // Header dinamis (Judul beda antara User & Admin)
                headerPage(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      getHistoryReport(); // Fitur Pull-to-Refresh
                    },
                    child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              BlocBuilder<HistoryBloc, HistoryState>(
                                builder: (context, state) {
                                  if (state is HistoryGetSuccess) {
                                    final histories = state.histories;
                                    if (histories.isNotEmpty) {
                                      return Column(children: [
                                        // Widget Filter (Dropdown & DatePicker)
                                        buttonFilter(histories),

                                        // Menampilkan List jika hasil filter tidak kosong
                                        _historiesFiltered(histories).isNotEmpty
                                            ? groupedListView(histories)
                                            : isEmptyText(),
                                      ]);
                                    } else {
                                      // Tampilan jika data kosong sama sekali
                                      return isEmptyText();
                                    }
                                  } else {
                                    return const SizedBox();
                                  }
                                },
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ],
            ),
            // Loading Overlay
            Center(
              child: BlocBuilder<HistoryBloc, HistoryState>(
                builder: (context, state) {
                  if (state is HistoryLoading) {
                    return const CustomLoading();
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Month Picker: Dialog khusus untuk memilih Bulan & Tahun.
  // Lebih relevan untuk laporan bulanan dibanding DatePicker biasa yang per tanggal.
  Future<void> monthPicker(BuildContext contexto) async {
    return await showMonthPicker(
      context: contexto,
      firstDate: DateTime(DateTime.now().year - 2, 5), // Batas bawah 2 tahun lalu
      lastDate: DateTime(DateTime.now().year + 2, 9),  // Batas atas 2 tahun depan
      initialDate: selectedDate ?? DateTime.now(),
      confirmWidget: Text(
        'Pilih',
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.w700,
          color: Colors.blueAccent,
        ),
      ),
      cancelWidget: Text(
        'Batal',
        style: GoogleFonts.openSans(
          fontWeight: FontWeight.w700,
          color: Colors.redAccent,
        ),
      ),
      monthPickerDialogSettings: MonthPickerDialogSettings(
        headerSettings: PickerHeaderSettings(
          headerBackgroundColor: Colors.blueAccent,
          headerCurrentPageTextStyle: GoogleFonts.openSans(
            fontSize: 14,
            color: Colors.white,
          ),
          headerSelectedIntervalTextStyle: GoogleFonts.openSans(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).then((DateTime? date) {
      if (date != null) {
        setState(() {
          selectedDate = date;
          // Update teks filter agar user tahu sedang memfilter bulan apa
          titleFilter =
          "Bulan ${ParsingString().convertDateOnlyMonth(date.toString())}";
        });
      }
    });
  }

  // Widget Tombol Filter di pojok kanan atas list.
  buttonFilter(List<HistoryModel> histories) {
    final List<String> menuOptions = [
      'Semua Laporan',
      'Bulan Ini',
      'Pilih Bulan',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Menampilkan teks filter yang sedang aktif
        Expanded(
          child: Text(
            titleFilter,
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Popup Menu untuk pilihan filter
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_alt),
          onSelected: (String value) {
            if (value == "Pilih Bulan") {
              monthPicker(context); // Buka dialog month picker
            } else {
              setState(() {
                titleFilter = value;
              });
            }
          },
          itemBuilder: (BuildContext context) {
            return menuOptions.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(
                  choice,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  /// Fungsi Inti Filtering: Menyaring list data berdasarkan kriteria 'titleFilter'.
  /// Dilakukan di sisi Client (Local Filtering) agar tidak perlu request ulang ke database setiap ganti filter.
  List<HistoryModel> _historiesFiltered(List<HistoryModel> histories) {
    if (titleFilter == "Semua Laporan") {
      return histories;
    } else if (titleFilter == "Bulan Ini") {
      return histories
          .where(
            (element) =>
        ParsingString().convertDateOnlyMonth(element.dateStart!) ==
            ParsingString().convertDateOnlyMonth(DateTime.now().toString()),
      )
          .toList();
    } else if (titleFilter ==
        "Bulan ${ParsingString().convertDateOnlyMonth(selectedDate.toString())}") {
      return histories
          .where(
            (element) =>
        ParsingString().convertDateOnlyMonth(element.dateStart!) ==
            ParsingString().convertDateOnlyMonth(selectedDate.toString()),
      )
          .toList();
    } else {
      return histories;
    }
  }

  // Menggunakan GroupedListView dari package 'grouped_list'.
  // Fungsinya mengelompokkan item list berdasarkan Bulan & Tahun secara otomatis.
  // Ini bikin tampilan riwayat jauh lebih rapi dibanding list biasa yang datar.
  groupedListView(List<HistoryModel> histories) {
    return GroupedListView<HistoryModel, String>(
      padding: EdgeInsets.zero,
      elements: _historiesFiltered(histories),
      shrinkWrap: true,
      // Sorting item di dalam grup berdasarkan tanggal selesai
      itemComparator: (a, b) => a.dateFinished!.compareTo(b.dateFinished!),
      // Kunci pengelompokan: Format 'yyyy MM' (Contoh: 2024 08)
      groupBy: (element) => element.dateFinished == ""
          ? "A"
          : DateFormat('yyyy MM').format(DateTime.parse(element.dateFinished!)),
      order: GroupedListOrder.DESC, // Urutkan grup dari yang terbaru (Descending)
      // Widget Header untuk setiap grup (Separator)
      groupSeparatorBuilder: (String value) {
        return _groupSeparatorBuilder(value);
      },
      // Widget Item List
      itemBuilder: (context, element) {
        return HistoryCardView(
          history: element,
          function: () {},
          role: userRole,
        );
      },
    );
  }

  // Widget Separator (Judul Grup Bulan/Tahun)
  Padding _groupSeparatorBuilder(String value) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Konversi '2024 08' jadi 'Agustus 2024' biar human-readable
            ParsingString().convertDateSwitchPosition(value),
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(
            thickness: 1,
            height: 1,
            color: Colors.grey,
          )
        ],
      ),
    );
  }

  // Widget Empty State: Tampilan user-friendly jika data kosong
  isEmptyText() {
    if (userRole == "1") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "Tidak ada laporan reservasi",
            style: GoogleFonts.openSans(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (userRole == "2") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "Tidak ada riwayat reservasi",
            style: GoogleFonts.openSans(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  // Header teks yang berubah sesuai Role
  headerPage() {
    if (userRole == "1") {
      return const HeaderPage(
        name: "Laporan", // Bahasa Admin
      );
    } else if (userRole == "2") {
      return const HeaderPage(
        name: "Riwayat Reservasi", // Bahasa User
      );
    } else {
      return const SizedBox();
    }
  }
}