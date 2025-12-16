import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/bloc/building/building_bloc.dart';
import '../../../data/bloc/extracurricular/extracurricular_bloc.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/header_pages.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_loading.dart';
import '../extracurricular/widget_extracurricular_card_view.dart';
import 'widget_building_card_view.dart';
import '../../widgets/general/custom_fab.dart';

class BuildingPage extends StatefulWidget {
  const BuildingPage({super.key});

  @override
  State<BuildingPage> createState() => _BuildingPageState();
}

// Saya menggunakan TickerProviderStateMixin karena halaman ini punya TabController kustom.
// Mixin ini wajib ada kalau kita bikin TabController secara manual (bukan cuma pakai DefaultTabController).
class _BuildingPageState extends State<BuildingPage>
    with TickerProviderStateMixin {

  late BuildingBloc buildingBloc;
  late ExtracurricularBloc excurBloc;
  late String roleUser;

  // Controller ini penting banget buat handle perpindahan tab (Gedung <-> Ekskul).
  // Saya perlu akses variabel ini buat tahu user lagi di tab mana (index berapa),
  // supaya tombol tambahnya (FAB) bisa berubah fungsi sesuai tab yang aktif.
  late TabController tabController;
  int selectedIndex = 0;

  /// Trigger event ke Bloc untuk ambil data gedung dari Firebase.
  getBuilding() {
    buildingBloc = context.read<BuildingBloc>();
    buildingBloc.add(GetBuildingByAgency());
  }

  /// Trigger event ke Bloc untuk ambil data ekskul.
  getExtracurricular() {
    excurBloc = context.read<ExtracurricularBloc>();
    excurBloc.add(GetExtracurricular());
  }

  /// Cek role user dari Local Storage (SharedPreferences).
  /// Ini krusial buat security UI: Tombol "Tambah/Hapus" cuma muncul kalau role-nya '1' (SuperAdmin).
  getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roleUser = prefs.getString("role")!;
    setState(() {
      roleUser = roleUser;
    });
  }

  /// Fungsi hapus ekskul yang di-pass ke widget card.
  deleteExcur(String id) {
    return () {
      excurBloc = context.read<ExtracurricularBloc>();
      excurBloc.add(DeleteExtracurricular(id));
    };
  }

  /// Fungsi hapus gedung.
  deleteBuilding(String id) {
    return () {
      buildingBloc = context.read<BuildingBloc>();
      buildingBloc.add(DeleteBuilding(id));
    };
  }

  @override
  void didChangeDependencies() {
    // Inisialisasi data awal saat halaman pertama kali dibangun.
    roleUser = "";
    getRole();
    getBuilding();
    getExtracurricular();

    // Inisialisasi TabController untuk 2 tab.
    // 'vsync: this' butuh TickerProviderStateMixin di atas.
    tabController = TabController(
      length: 2,
      vsync: this,
    );
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Wajib dispose tabController buat mencegah memory leak kalau halaman ditutup.
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Floating Action Button (FAB) dipisah ke fungsi customFAB()
        // biar kodenya bersih dan logic-nya terisolasi.
        floatingActionButton: customFAB(),
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderPage(
                  name: "Gedung & Ekstrakurikuler",
                ),
                const Gap(10),
                // TabBar untuk navigasi Gedung vs Ekskul
                TabBar(
                  controller: tabController,
                  // Logic onTap: Setiap kali tab dipencet, saya update 'selectedIndex'.
                  // Ini memicu rebuild UI supaya tombol FAB berubah sesuai tab yang dipilih.
                  onTap: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  labelStyle: GoogleFonts.openSans(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelColor: Colors.black,
                  labelColor: Colors.white,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  tabs: [
                    // Tab 1: Gedung
                    Tab(
                      child: Container(
                        width: double.maxFinite,
                        height: 40,
                        // Logic warna tombol tab aktif/non-aktif
                        decoration: selectedIndex == 0
                            ? BoxDecoration(
                          color: Colors.blueAccent.shade400,
                          borderRadius: BorderRadius.circular(10),
                        )
                            : BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text("Gedung"),
                        ),
                      ),
                    ),
                    // Tab 2: Jadwal Ekskul
                    Tab(
                      child: Container(
                        width: double.maxFinite,
                        height: 40,
                        decoration: selectedIndex == 1
                            ? BoxDecoration(
                          color: Colors.blueAccent.shade400,
                          borderRadius: BorderRadius.circular(10),
                        )
                            : BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text("Jadwal Ekskul"),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: [
                      /// View 1: List Gedung
                      buildingContent(),

                      /// View 2: List Ekskul
                      extracurricularContent(),
                    ],
                  ),
                ),
              ],
            ),

            // Overlay Loading: Muncul di tengah layar kalau Bloc sedang loading data Gedung
            Center(
              child: BlocBuilder<BuildingBloc, BuildingState>(
                builder: (context, state) {
                  if (state is BuildingLoading) {
                    return const CustomLoading();
                  }
                  return const SizedBox();
                },
              ),
            ),
            // Overlay Loading: Muncul kalau Bloc sedang loading data Ekskul
            Center(
              child: BlocBuilder<ExtracurricularBloc, ExtracurricularState>(
                builder: (context, state) {
                  if (state is ExtracurricularLoading) {
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

  // Widget konten untuk Tab Gedung
  BlocListener buildingContent() {
    return BlocListener<BuildingBloc, BuildingState>(
      listener: (context, state) {
        // Listener cuma buat nampilin notifikasi sukses hapus, bukan buat render UI.
        if (state is BuildingDeleteSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menghapus gedung",
            Icons.check_circle,
          );
        }
      },
      child: RefreshIndicator(
        // Fitur Pull-to-Refresh: User bisa tarik layar buat reload data terbaru.
        onRefresh: () async {
          getBuilding();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: BlocBuilder<BuildingBloc, BuildingState>(
            builder: (context, state) {
              if (state is BuildingGetSuccess) {
                final buildings = state.buildings;
                // Sorting nama gedung A-Z biar user gampang nyarinya.
                buildings.sort((a, b) => a.name!.compareTo(b.name!));

                if (buildings.isNotEmpty) {
                  return Column(
                    children: [
                      const Gap(10),
                      Text(
                        "Daftar Gedung",
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // ListView.builder efisien buat list panjang karena item dirender pas discroll aja (Lazy Loading).
                      ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                          top: 10,
                        ),
                        itemCount: buildings.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: BuildingCardView(
                              building: buildings[index],
                              // Navigasi ke Edit
                              editFunction: () {
                                context.pushNamed(
                                  Routes().editBuilding,
                                  extra: buildings[index],
                                );
                              },
                              // Navigasi ke Hapus (panggil fungsi deleteBuilding)
                              deleteFunction: () {
                                PopUp().whenDoSomething(
                                    context,
                                    "Hapus ${buildings[index].name}?",
                                    Icons.delete_forever,
                                    deleteBuilding(
                                      buildings[index].id!,
                                    ));
                              },
                              // Navigasi ke Detail
                              detailFunction: () {
                                context.pushNamed(
                                  Routes().detailBuilding,
                                  extra: buildings[index],
                                );
                              },
                              role: roleUser,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  // State Empty: Tampilan kalau data kosong
                  return Column(
                    children: [
                      const Gap(30),
                      Center(
                        child: Text(
                          "Tidak ada gedung",
                          style: GoogleFonts.openSans(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }

  // Widget konten untuk Tab Ekskul (Strukturnya mirip sama buildingContent)
  BlocListener extracurricularContent() {
    return BlocListener<ExtracurricularBloc, ExtracurricularState>(
      listener: (context, state) {
        if (state is ExtracurricularDeleteSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menghapus ekskul",
            Icons.check_circle,
          );
        }
      },
      child: RefreshIndicator(
        onRefresh: () async {
          getExtracurricular();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: BlocBuilder<ExtracurricularBloc, ExtracurricularState>(
            builder: (context, state) {
              if (state is ExtracurricularGetSuccess) {
                final excur = state.extracurriculars;
                excur.sort((a, b) => a.name!.compareTo(b.name!));
                if (excur.isNotEmpty) {
                  return Column(
                    children: [
                      const Gap(10),
                      Text(
                        "Daftar Ekstrakurikuler",
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                          top: 10,
                        ),
                        itemCount: excur.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ExtracurricularCardView(
                              excur: excur[index],
                              editFunction: () {
                                context.pushNamed(
                                  Routes().editExtracurricular,
                                  extra: excur[index],
                                );
                              },
                              deleteFunction: () {
                                PopUp().whenDoSomething(
                                  context,
                                  "Hapus ${excur[index].name!}?",
                                  Icons.delete_forever,
                                  deleteExcur(excur[index].id!),
                                );
                              },
                              detailFunction: () {
                                context.pushNamed(
                                  Routes().detailExtracurricular,
                                  extra: excur[index],
                                );
                              },
                              role: roleUser,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const Gap(30),
                      Center(
                        child: Text(
                          "Tidak ada ekstrakurikuler",
                          style: GoogleFonts.openSans(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ),
    );
  }

  // Logic FAB Dinamis: Ini fitur penting buat UX.
  // 1. Cek Role: Cuma 'SuperAdmin' (role == "1") yang boleh lihat tombol ini.
  // 2. Cek Tab: Kalau lagi di tab Gedung (index 0) -> Buka halaman Tambah Gedung.
  //             Kalau lagi di tab Ekskul (index 1) -> Buka halaman Tambah Ekskul.
  customFAB() {
    if (roleUser == "1") {
      if (selectedIndex == 0) {
        return CustomFAB(
          iconData: Icons.add_home_work,
          function: () {
            context.pushNamed(
              Routes().createBuilding,
            );
          },
        );
      } else {
        return CustomFAB(
          iconData: Icons.add_home_work,
          function: () {
            context.pushNamed(
              Routes().createExtracurricular,
            );
          },
        );
      }
    } else {
      // Kalau user biasa, return SizedBox (alias gak nampilin apa-apa).
      return const SizedBox();
    }
  }
}