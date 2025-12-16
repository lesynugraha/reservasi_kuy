import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:reservation_app/src/presentation/widgets/general/widget_custom_title_text_form_field.dart';
import 'package:reservation_app/src/presentation/widgets/general/pop_up.dart';
import 'package:reservation_app/src/presentation/widgets/general/widget_custom_text_form_field.dart';

import '../../../data/bloc/building/building_bloc.dart';
import '../../../data/model/building_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/image_picker.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/widget_custom_loading.dart';

class EditBuildingPage extends StatefulWidget {
  // Wajib menerima parameter 'building' agar form bisa terisi otomatis dengan data lama
  const EditBuildingPage({super.key, required this.building});

  final BuildingModel building;

  @override
  State<EditBuildingPage> createState() => _EditBuildingPageState();
}

class _EditBuildingPageState extends State<EditBuildingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController buildingNameController;
  late TextEditingController buildingBaseNameController;
  late TextEditingController descController;
  late TextEditingController facilityController;
  late TextEditingController capacityController;
  late TextEditingController ruleController;
  late TextEditingController imageController;
  late BuildingBloc _buildingBloc;
  late String _selectedValue;
  Uint8List? imagePicked;

  /// Fungsi utama untuk menyimpan perubahan data gedung.
  /// Menggunakan logika percabangan untuk efisiensi upload.
  updateBuilding(BuildContext context) {
    return () async {
      // Skenario 1: Admin mengganti gambar gedung.
      // Maka perlu proses upload ulang ke Firebase Storage sebelum update data di Firestore.
      if (imagePicked != null) {
        final urlImage = await StoreData().uploadImageToStorage(
          "building",
          DateFormat('yyyyMMddHHmmss').format(DateTime.now()),
          imagePicked!,
        );

        if (!context.mounted) return;
        _buildingBloc = context.read<BuildingBloc>();
        _buildingBloc.add(
          UpdateBuilding(
            widget.building.id!,
            buildingNameController.text,
            descController.text,
            facilityController.text,
            int.parse(capacityController.text),
            ruleController.text,
            urlImage, // URL baru hasil upload
            widget.building.name!,
            _selectedValue,
          ),
        );
      } else {
        // Skenario 2: Admin HANYA mengubah teks (Nama, Deskripsi, dll) tanpa ganti gambar.
        // Langsung pakai URL lama (imageController.text) agar tidak perlu upload ulang (hemat bandwidth).
        _buildingBloc = context.read<BuildingBloc>();
        _buildingBloc.add(
          UpdateBuilding(
            widget.building.id!,
            buildingNameController.text,
            descController.text,
            facilityController.text,
            int.parse(capacityController.text),
            ruleController.text,
            imageController.text, // Masih menggunakan URL gambar yang lama
            widget.building.name!,
            _selectedValue,
          ),
        );
      }
    };
  }

  /// Mengambil gambar baru dari galeri lokal perangkat
  selectImage() async {
    Uint8List img = await StoreData().pickImage(ImageSource.gallery);
    setState(() {
      imagePicked = img;
    });
  }

  // Helper widget untuk menampilkan preview gambar.
  // Menangani 3 kondisi: Gambar default, Gambar dari URL (Cached), atau Gambar kosong.
  imageLoader() {
    if (widget.building.image! == "") {
      return const Image(
        height: 250,
        width: double.infinity,
        fit: BoxFit.cover,
        image: AssetImage(assetsDefaultBuildingImage),
      );
    } else {
      return CachedNetworkImage(
        height: 250,
        width: double.infinity,
        imageUrl: widget.building.image!,
        placeholder: (context, url) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
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
  void initState() {
    // Inisialisasi status dropdown (Tersedia/Tidak Tersedia) sesuai data di database
    _selectedValue = widget.building.status!;

    // Pre-fill semua Text Controller dengan data yang diterima dari parameter widget.building.
    // Ini UX standar halaman Edit: User melihat data lama dulu sebelum mengubahnya.
    buildingNameController = TextEditingController(text: widget.building.name);
    buildingBaseNameController =
        TextEditingController(text: widget.building.name);
    descController = TextEditingController(text: widget.building.description);
    facilityController = TextEditingController(text: widget.building.facility);
    capacityController =
        TextEditingController(text: widget.building.capacity.toString());
    ruleController = TextEditingController(text: widget.building.rule);
    imageController = TextEditingController(text: widget.building.image);
    super.initState();
  }

  @override
  void dispose() {
    // Membersihkan controller dari memori saat halaman ditutup
    buildingNameController.dispose();
    buildingBaseNameController.dispose();
    descController.dispose();
    facilityController.dispose();
    capacityController.dispose();
    ruleController.dispose();
    imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BuildingBloc, BuildingState>(
      listener: (context, state) {
        if (state is BuildingUpdateSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Perubahan berhasil",
            Icons.check_circle,
            true,
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderDetailPage(pageName: "Edit Gedung"),
                Expanded(
                  child: RefreshIndicator(
                    // Fitur reset form ke kondisi awal database jika user menarik layar (pull-to-refresh)
                    onRefresh: () async {
                      setState(() {
                        buildingNameController =
                            TextEditingController(text: widget.building.name);
                        descController = TextEditingController(
                            text: widget.building.description);
                        facilityController = TextEditingController(
                            text: widget.building.facility);
                        capacityController = TextEditingController(
                            text: widget.building.capacity.toString());
                        ruleController =
                            TextEditingController(text: widget.building.rule);
                        imageController =
                            TextEditingController(text: widget.building.image);
                      });
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(10),
                              Center(
                                child: Stack(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        // Prioritaskan menampilkan gambar baru jika user sudah memilih dari galeri (imagePicked).
                                        // Jika belum ada pilih baru, tampilkan gambar lama (imageLoader).
                                        if (imagePicked != null) {
                                          return Image(
                                            height: 250,
                                            width: double.infinity,
                                            image: MemoryImage(imagePicked!),
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return imageLoader();
                                        }
                                      },
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent
                                              .withOpacity(0.3),
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
                                    // Tombol hapus preview gambar baru (cancel upload)
                                    imagePicked != null
                                        ? Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blueAccent
                                              .withOpacity(0.3),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                imagePicked = null;
                                              });
                                            },
                                            customBorder:
                                            const CircleBorder(),
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
                              const Gap(10),
                              const CustomTitleTextFormField(
                                subtitle: "Nama Gedung",
                              ),
                              CustomTextFormField(
                                fieldName: "Nama Gedung",
                                controller: buildingNameController,
                                prefixIcon: Icons.corporate_fare,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Deskripsi",
                              ),
                              CustomTextFormField(
                                fieldName: "Deskripsi Gedung",
                                controller: descController,
                                prefixIcon: Icons.description,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Fasilitas",
                              ),
                              CustomTextFormField(
                                fieldName: "Fasilitas Gedung",
                                controller: facilityController,
                                prefixIcon: Icons.badge,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Kapasitas",
                              ),
                              CustomTextFormField(
                                fieldName: "Kapasitas Gedung",
                                controller: capacityController,
                                prefixIcon: Icons.groups,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Peraturan",
                              ),
                              CustomTextFormField(
                                fieldName: "Peraturan Gedung",
                                controller: ruleController,
                                prefixIcon: Icons.rule,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Status",
                              ),
                              // Dropdown untuk mengubah status ketersediaan gedung secara manual
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.event_available),
                                  hintStyle: GoogleFonts.openSans(),
                                  hintText: "Status Gedung",
                                  border: const OutlineInputBorder(),
                                ),
                                value: _selectedValue,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Tersedia',
                                      child: Text('Tersedia')),
                                  DropdownMenuItem(
                                      value: 'Tidak Tersedia',
                                      child: Text('Tidak Tersedia')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedValue = value!;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Silakan pilih status ketersediaan';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(15),
                              BlocBuilder<BuildingBloc, BuildingState>(
                                builder: (context, state) {
                                  if (state is BuildingUpdateFailed) {
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
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ButtonPositive(
                                  name: "Simpan",
                                  function: () {
                                    if (_formKey.currentState!.validate()) {
                                      PopUp().whenDoSomething(
                                        context,
                                        "Simpan perubahan?",
                                        Icons.question_mark,
                                        updateBuilding(context),
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
                  ),
                ),
              ],
            ),
            // Indikator loading yang muncul di tengah layar saat proses update berjalan
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
    );
  }
}