import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:reservation_app/src/presentation/widgets/general/widget_custom_loading.dart';

import '../../../data/bloc/building/building_bloc.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/image_picker.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_text_form_field.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';
import 'widget_edit_building_card_view.dart';

class AddBuildingPage extends StatefulWidget {
  const AddBuildingPage({super.key});

  @override
  State<AddBuildingPage> createState() => _AddBuildingPageState();
}

// Menggunakan TickerProviderStateMixin karena halaman ini memerlukan TabController
// untuk animasi perpindahan antara tab 'Tambah' dan 'Edit/Hapus'.
class _AddBuildingPageState extends State<AddBuildingPage>
    with TickerProviderStateMixin {

  // Controller untuk menghandle inputan form
  late TextEditingController buildingNameController;
  late TextEditingController descController;
  late TextEditingController facilityController;
  late TextEditingController capacityController;
  late TextEditingController ruleController;
  late TextEditingController imageController;
  late TextEditingController statusController;

  late TabController _tabController;
  late BuildingBloc _buildingBloc;

  // GlobalKey untuk validasi form (cek apakah input kosong/tidak valid)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variabel untuk menampung gambar sementara dalam bentuk bytes sebelum diupload
  Uint8List? imagePicked;

  /// Logika inti penambahan gedung.
  /// Alur: Cek apakah user memilih gambar -> Upload ke Firebase Storage -> Ambil URL -> Simpan data ke Firestore.
  /// Jika tidak ada gambar, langsung simpan data teks saja.
  addBuilding(BuildContext context) {
    return () async {
      // Skenario 1: User upload gambar
      if (imagePicked != null) {
        // Upload gambar ke storage dengan nama file unik (timestamp)
        final urlImage = await StoreData().uploadImageToStorage(
          "building",
          DateFormat('yyyyMMddHHmmss').format(DateTime.now()),
          imagePicked!,
        );

        if (!context.mounted) return;
        _buildingBloc = context.read<BuildingBloc>();
        // Trigger event tambah data dengan menyertakan URL gambar dari storage
        _buildingBloc.add(
          AddBuilding(
            buildingNameController.text,
            descController.text,
            facilityController.text,
            int.parse(capacityController.text),
            ruleController.text,
            urlImage,
          ),
        );
      } else {
        // Skenario 2: User tidak upload gambar (pakai default atau string kosong)
        _buildingBloc = context.read<BuildingBloc>();
        _buildingBloc.add(
          AddBuilding(
            buildingNameController.text,
            descController.text,
            facilityController.text,
            int.parse(capacityController.text),
            ruleController.text,
            imageController.text,
          ),
        );
      }
    };
  }

  /// Trigger event untuk mengambil daftar gedung terbaru dari database (refresh data).
  _getBuilding() {
    _buildingBloc = context.read<BuildingBloc>();
    _buildingBloc.add(GetBuildingByAgency());
  }

  /// Trigger event hapus gedung berdasarkan ID dokumen.
  deleteBuilding(String id) {
    return () {
      _buildingBloc = context.read<BuildingBloc>();
      _buildingBloc.add(DeleteBuilding(id));
    };
  }

  /// Memanggil image picker (galeri) dan menyimpan hasilnya ke state lokal (imagePicked)
  /// untuk ditampilkan sebagai preview sebelum diupload.
  selectImage() async {
    Uint8List img = await StoreData().pickImage(ImageSource.gallery);
    setState(() {
      imagePicked = img;
    });
  }

  @override
  void initState() {
    buildingNameController = TextEditingController();
    descController = TextEditingController();
    facilityController = TextEditingController();
    capacityController = TextEditingController();
    ruleController = TextEditingController();
    imageController = TextEditingController();
    statusController = TextEditingController();
    // Inisialisasi tab controller untuk 2 tab (Tambah & Manage)
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // Wajib dispose controller untuk mencegah memory leak
    super.dispose();
    _tabController.dispose();
    buildingNameController.dispose();
    descController.dispose();
    facilityController.dispose();
    capacityController.dispose();
    ruleController.dispose();
    imageController.dispose();
    statusController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener digunakan untuk menangani feedback/side-effect (Popup Sukses/Gagal).
    // Tidak mereturn widget UI, hanya menjalankan logic ketika state berubah.
    return BlocListener<BuildingBloc, BuildingState>(
      listener: (context, state) {
        if (state is BuildingAddSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menambah gedung",
            Icons.check_circle,
            true,
          );
        } else if (state is BuildingDeleteSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menghapus gedung",
            Icons.check_circle,
            true,
          );
          context.pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  const HeaderDetailPage(
                    pageName: "Tambah Gedung",
                  ),
                  // TabBar navigasi antar fitur dalam satu halaman
                  TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.openSans(
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(text: 'Tambah'),
                      Tab(text: 'Edit/Hapus'),
                    ],
                  ),
                  Expanded(
                    // TabBarView berisi konten sesuai tab yang dipilih
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        /// Tab 1: Form tambah gedung
                        addBuildingContent(),

                        /// Tab 2: List manajemen gedung (Edit/Hapus)
                        manageBuildingContent(),
                      ],
                    ),
                  ),
                ],
              ),
              // Overlay Loading Indicator
              // Muncul di tengah layar hanya saat state sedang 'BuildingLoading'
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
            ],
          ),
        ),
      ),
    );
  }

  // Widget konten untuk Tab 1 (Form Input)
  RefreshIndicator addBuildingContent() {
    return RefreshIndicator(
      onRefresh: () async {}, // Pull to refresh kosong (opsional)
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Form(
            key: _formKey, // Key untuk validasi
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(10),
                // Area upload & preview gambar
                Center(
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          // Logic tampilan gambar:
                          // 1. Jika user pilih gambar baru (imagePicked), tampilkan itu.
                          // 2. Jika tidak, tampilkan placeholder default.
                          if (imagePicked != null) {
                            return Image(
                              height: 250,
                              width: double.infinity,
                              image: MemoryImage(imagePicked!),
                              fit: BoxFit.cover,
                            );
                          } else {
                            if (imageController.text == "") {
                              return const Image(
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                image: AssetImage(assetsDefaultBuildingImage),
                              );
                            } else {
                              return const Image(
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                image: AssetImage(assetsDefaultBuildingImage),
                              );
                            }
                          }
                        },
                      ),
                      // Tombol Edit/Pilih Gambar (Pojok Kanan Bawah)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                selectImage();
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  imagePicked != null
                                      ? Icons.edit
                                      : Icons.add_photo_alternate,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Tombol Hapus Gambar (Pojok Kanan Atas - Muncul jika gambar dipilih)
                      imagePicked != null
                          ? Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  imagePicked = null;
                                });
                              },
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                          : const SizedBox(),
                    ],
                  ),
                ),
                const Gap(20),
                // Form Fields
                const CustomTitleTextFormField(subtitle: "Nama Gedung"),
                CustomTextFormField(
                  fieldName: "Nama Gedung",
                  controller: buildingNameController,
                  prefixIcon: Icons.corporate_fare,
                ),
                const CustomTitleTextFormField(subtitle: "Deskripsi"),
                CustomTextFormField(
                  fieldName: "Deskripsi Gedung",
                  controller: descController,
                  prefixIcon: Icons.description,
                ),
                const CustomTitleTextFormField(subtitle: "Fasilitas"),
                CustomTextFormField(
                  fieldName: "Fasilitas Gedung",
                  controller: facilityController,
                  prefixIcon: Icons.badge,
                ),
                const CustomTitleTextFormField(subtitle: "Kapasitas"),
                CustomTextFormField(
                  fieldName: "Kapasitas Gedung",
                  controller: capacityController,
                  prefixIcon: Icons.groups,
                ),
                const CustomTitleTextFormField(subtitle: "Peraturan"),
                CustomTextFormField(
                  fieldName: "Peraturan Gedung",
                  controller: ruleController,
                  prefixIcon: Icons.rule,
                ),
                const Gap(15),
                // Menampilkan pesan error jika proses tambah gagal
                BlocBuilder<BuildingBloc, BuildingState>(
                  builder: (context, state) {
                    if (state is BuildingAddFailed) {
                      return Center(
                        child: Text(
                          state.error,
                          style: GoogleFonts.openSans(
                            color: Colors.redAccent,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const Gap(15),
                // Tombol Submit
                Align(
                  alignment: Alignment.bottomRight,
                  child: ButtonPositive(
                    name: "Tambah",
                    function: () {
                      // Validasi input sebelum eksekusi logic
                      if (_formKey.currentState!.validate()) {
                        PopUp().whenDoSomething(
                          context,
                          "Tambah gedung?",
                          Icons.corporate_fare,
                          addBuilding(context),
                        );
                      }
                    },
                  ),
                ),
                const Gap(30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget konten untuk Tab 2 (Manajemen List)
  RefreshIndicator manageBuildingContent() {
    return RefreshIndicator(
      onRefresh: () async {
        _getBuilding(); // Refresh data saat ditarik ke bawah
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menggunakan BlocBuilder untuk merender list sesuai state data terbaru
              BlocBuilder<BuildingBloc, BuildingState>(
                builder: (context, state) {
                  if (state is BuildingGetSuccess) {
                    final buildings = state.buildings;
                    if (buildings.isNotEmpty) {
                      return Column(
                        children: [
                          Text(
                            "Daftar Gedung",
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(10),
                          // List view untuk menampilkan kartu gedung
                          ListView.builder(
                            itemCount: buildings.length,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              bottom: 80,
                            ),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: EditBuildingCardView(
                                  building: buildings[index],
                                  // Navigasi ke halaman edit dengan membawa data objek gedung
                                  functionEdit: () {
                                    context.pushNamed(
                                      Routes().editBuilding,
                                      extra: buildings[index],
                                    );
                                  },
                                  // Trigger dialog konfirmasi hapus
                                  functionDelete: () {
                                    PopUp().whenDoSomething(
                                      context,
                                      "Ingin menghapus ${buildings[index].name}?",
                                      Icons.delete_forever,
                                      deleteBuilding(buildings[index].id!),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    } else {
                      // Tampilan jika data kosong
                      return Container(
                        decoration:
                        const BoxDecoration(color: Color(0x80FFFFFF)),
                        child: Center(
                          child: Text(
                            "Tidak ada data gedung",
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}