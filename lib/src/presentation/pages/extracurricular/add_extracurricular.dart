import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:reservation_app/src/presentation/pages/extracurricular/widget_edit_extracurricular_card_view.dart';

import '../../../data/bloc/extracurricular/extracurricular_bloc.dart';
import '../../../data/model/user_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/image_picker.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/widget_custom_text_form_field.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';

class AddExtracurricularPage extends StatefulWidget {
  const AddExtracurricularPage({super.key});

  @override
  State<AddExtracurricularPage> createState() => _AddExtracurricularPageState();
}

// Menggunakan TickerProviderStateMixin untuk mendukung animasi perpindahan TabBar secara manual.
class _AddExtracurricularPageState extends State<AddExtracurricularPage>
    with TickerProviderStateMixin {

  // Controller untuk input text field
  late TextEditingController excurNameController;
  late TextEditingController descController;
  late TextEditingController scheduleController;
  late TextEditingController imageController;

  // Controller navigasi tab (Tambah vs Manage)
  late TabController _tabController;
  late ExtracurricularBloc excurBloc;
  late UserModel user;

  // Key untuk validasi form sebelum submit
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Variabel penampung byte gambar sementara sebelum diupload
  Uint8List? imagePicked;

  /// Fungsi inti menambahkan kegiatan.
  /// Alurnya: Cek gambar -> Upload (jika ada) -> Trigger Event Bloc untuk simpan ke Firestore.
  addExcur(BuildContext context) {
    return () async {
      // Kondisi 1: User menyertakan gambar.
      if (imagePicked != null) {
        // Upload ke Firebase Storage
        final urlImage = await StoreData().uploadImageToStorage(
          "extracurricular",
          DateFormat('yyyyMMddHHmmss').format(DateTime.now()), // Nama file unik
          imagePicked!,
        );

        // Cek mounted sebelum pakai context (mencegah error async gap)
        if (!context.mounted) return;

        excurBloc = context.read<ExtracurricularBloc>();
        // Kirim event tambah data dengan URL gambar baru
        excurBloc.add(
          AddExtracurricular(
            excurNameController.text,
            descController.text,
            scheduleController.text,
            urlImage,
          ),
        );
      } else {
        // Kondisi 2: User tidak upload gambar (pakai default/kosong).
        excurBloc = context.read<ExtracurricularBloc>();
        excurBloc.add(
          AddExtracurricular(
            excurNameController.text,
            descController.text,
            scheduleController.text,
            imageController.text,
          ),
        );
      }
    };
  }

  /// Trigger event hapus data ekskul berdasarkan ID dokumen.
  deleteExcur(String id) {
    return () {
      excurBloc = context.read<ExtracurricularBloc>();
      excurBloc.add(DeleteExtracurricular(id));
    };
  }

  /// Trigger event untuk refresh/ambil data terbaru dari database.
  getExcur() {
    excurBloc = context.read<ExtracurricularBloc>();
    excurBloc.add(GetExtracurricular());
  }

  /// Membuka galeri dan menyimpan gambar yang dipilih ke variabel state (imagePicked).
  selectImage() async {
    Uint8List img = await StoreData().pickImage(ImageSource.gallery);
    setState(() {
      imagePicked = img;
    });
  }

  @override
  void initState() {
    // Inisialisasi semua controller saat widget pertama kali dibuat
    excurNameController = TextEditingController();
    descController = TextEditingController();
    scheduleController = TextEditingController();
    imageController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    // Membersihkan resource controller untuk mencegah memory leak
    excurNameController.dispose();
    descController.dispose();
    scheduleController.dispose();
    imageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener hanya mendengarkan perubahan state untuk aksi non-UI (seperti Dialog/Snackbar).
    return BlocListener<ExtracurricularBloc, ExtracurricularState>(
      listener: (context, state) {
        if (state is ExtracurricularAddSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menambah ekskul",
            Icons.check_circle,
            true, // True artinya tutup dialog setelah sukses
          );
        } else if (state is ExtracurricularDeleteSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil menghapus ekskul",
            Icons.check_circle,
            true,
          );
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
                    pageName: "Tambah Kegiatan Ekstrakurikuler",
                  ),
                  // Tab navigasi di bagian atas
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
                    // Area konten yang berubah sesuai tab yang dipilih
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        /// Tab 1: Form Input
                        addExcurContent(),

                        /// Tab 2: List Manajemen Data
                        manageExcurContent(),
                      ],
                    ),
                  ),
                ],
              ),
              // Loading Indicator Overlay (muncul di tengah layar saat proses async berjalan)
              Center(
                child: BlocBuilder<ExtracurricularBloc, ExtracurricularState>(
                  builder: (context, state) {
                    if (state is ExtracurricularLoading) {
                      return Container(
                        decoration:
                        const BoxDecoration(color: Color(0x80FFFFFF)),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
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

  // Widget Form Input Data (Tab 1)
  RefreshIndicator addExcurContent() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Form(
            key: _formKey, // Key validasi
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(10),
                // Area Image Picker & Preview
                Center(
                  child: Stack(
                    children: [
                      Builder(
                        builder: (context) {
                          // Tampilkan preview gambar yang baru dipilih user
                          if (imagePicked != null) {
                            return Image(
                              height: 250,
                              width: double.infinity,
                              image: MemoryImage(imagePicked!),
                              fit: BoxFit.cover,
                            );
                          } else {
                            // Tampilkan placeholder jika belum ada gambar
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
                      // Tombol ikon kamera/edit di pojok gambar
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
                      // Tombol hapus gambar preview
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
                // Field Input Data
                const CustomTitleTextFormField(
                    subtitle: "Nama Ekstrakurikuler"),
                CustomTextFormField(
                  fieldName: "Nama Ekstrakurikuler",
                  controller: excurNameController,
                  prefixIcon: Icons.corporate_fare,
                ),
                const CustomTitleTextFormField(subtitle: "Deskripsi"),
                CustomTextFormField(
                  fieldName: "Deskripsi Ekstrakurikuler",
                  controller: descController,
                  prefixIcon: Icons.description,
                ),
                const CustomTitleTextFormField(subtitle: "Jadwal"),
                CustomTextFormField(
                  fieldName: "Jadwal Ekstrakurikuler",
                  controller: scheduleController,
                  prefixIcon: Icons.date_range,
                ),
                const Gap(15),
                // Menampilkan pesan error di bawah form jika gagal tambah
                BlocBuilder<ExtracurricularBloc, ExtracurricularState>(
                  builder: (context, state) {
                    if (state is ExtracurricularAddFailed) {
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
                      if (_formKey.currentState!.validate()) {
                        PopUp().whenDoSomething(
                          context,
                          "Tambah Ekstrakurikuler",
                          Icons.corporate_fare,
                          addExcur(context),
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

  // Widget List Manajemen Data (Tab 2)
  RefreshIndicator manageExcurContent() {
    return RefreshIndicator(
      // Fitur pull-to-refresh untuk reload data dari server
      onRefresh: () async {
        getExcur();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menggunakan BlocBuilder untuk merender list sesuai state data terbaru
              BlocBuilder<ExtracurricularBloc, ExtracurricularState>(
                builder: (context, state) {
                  if (state is ExtracurricularGetSuccess) {
                    final excur = state.extracurriculars;
                    if (excur.isNotEmpty) {
                      return Column(
                        children: [
                          Text(
                            "Jadwal Ekstrakurikuler",
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(10),
                          // ListView untuk menampilkan item ekskul
                          ListView.builder(
                            itemCount: excur.length,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              bottom: 80,
                            ),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: EditExtracurricularCardView(
                                  excur: excur[index],
                                  // Navigasi ke halaman Edit
                                  functionEdit: () {
                                    context.pushNamed(
                                      Routes().editExtracurricular,
                                      extra: excur[index],
                                    );
                                  },
                                  // Trigger dialog hapus
                                  functionDelete: () {
                                    PopUp().whenDoSomething(
                                      context,
                                      "Hapus ${excur[index].name}?",
                                      Icons.delete_forever,
                                      deleteExcur(
                                        excur[index].id!,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    } else {
                      // Tampilan state kosong (Empty State)
                      return Container(
                        decoration:
                        const BoxDecoration(color: Color(0x80FFFFFF)),
                        child: Center(
                          child: Text(
                            "Tidak ada data jadwal ekstrakurikuler",
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