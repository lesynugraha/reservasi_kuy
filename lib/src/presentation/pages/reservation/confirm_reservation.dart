import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../utils/general/image_picker.dart';
import '../../../data/bloc/reservation/reservation_bloc.dart';
import '../../../data/bloc/reservation_building/reservation_building_bloc.dart';
import '../../../data/bloc/user/user_bloc.dart';
import '../../../data/model/building_model.dart';
import '../../../data/model/user_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/parsing.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_loading.dart';
import '../../widgets/general/widget_custom_text_form_field.dart';
import '../../widgets/general/widget_title_subtitle.dart';

class ConfirmReservationPage extends StatefulWidget {
  // Wajib menerima data gedung dan tanggal yang dipilih dari halaman sebelumnya.
  // Ini memastikan data yang dikonfirmasi sesuai dengan pilihan user.
  const ConfirmReservationPage({
    super.key,
    required this.building,
    required this.dateStart,
    required this.dateEnd,
  });

  final BuildingModel building;
  final String dateStart;
  final String dateEnd;

  @override
  State<ConfirmReservationPage> createState() => _ConfirmReservationPageState();
}

class _ConfirmReservationPageState extends State<ConfirmReservationPage> {
  late TextEditingController informationController;
  late ReservationBloc _reservationBloc;
  late UserBloc _userBloc;
  late UserModel user;

  // Variabel state untuk menyimpan sementara file gambar bukti pengajuan dalam bentuk bytes.
  // Disimpan sebagai Uint8List agar kompatibel dengan web dan mobile.
  Uint8List? _imageProof;

  /// Fetch data user yang sedang login.
  /// Diperlukan untuk mengisi data pemesan secara otomatis di backend.
  getUser() {
    _userBloc = context.read<UserBloc>();
    _userBloc.add(GetUserLoggedIn());
  }

  /// Fungsi Membuka Galeri & Menyimpan Hasilnya.
  /// Menggunakan helper StoreData yang sudah ada untuk standardisasi cara pick image.
  Future<void> _pickProofImage() async {
    Uint8List? file = await StoreData().pickImage(ImageSource.gallery);
    if (file != null) {
      setState(() {
        _imageProof = file; // Update state untuk menampilkan preview
      });
    }
  }

  /// Fungsi Inti: Submit Reservasi.
  createReservation() {
    return () {
      _reservationBloc = context.read<ReservationBloc>();
      // Mengirim Event 'CreateReservation' ke Bloc.
      // Data yang dikirim mencakup detail gedung, data user, tanggal, keterangan, dan file bukti (jika ada).
      _reservationBloc.add(
        CreateReservation(
          widget.building.name!,
          user.username!,
          user.fullName!,
          user.email!,
          user.phone!,
          widget.dateStart,
          widget.dateEnd,
          informationController.text,
          user.agency!,
          widget.building.image!,
          _imageProof, // Mengirim file bukti untuk diupload di layer Repository
        ),
      );
    };
  }

  // Helper tampilan gambar gedung.
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
    getUser(); // Load data user saat inisialisasi
    informationController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    informationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener UserBloc: Mengambil data user yang berhasil diload
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserGetSuccess) {
              user = state.user;
            }
          },
        ),
        // Listener ReservationBloc: Menangani hasil submit (Sukses/Gagal)
        BlocListener<ReservationBloc, ReservationState>(
          listener: (context, state) {
            if (state is ReservationCreateSuccess) {
              // Jika sukses: Tampilkan popup sukses dan reset state ketersediaan gedung.
              PopUp().whenSuccessDoSomething(
                context,
                "Mohon untuk menunggu konfirmasi dari admin",
                Icons.check_circle,
                true, // true = tutup halaman confirm setelah sukses
              );
              // Trigger refresh data ketersediaan gedung agar update status terbaru
              BlocProvider.of<ReservationBuildingBloc>(context).add(
                InitialBuildingAvail(),
              );
            } else if (state is ReservationCreateFailed) {
              // Feedback jika gagal (misal koneksi error)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Gagal membuat reservasi")),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Mencegah layout rusak saat keyboard muncul
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderDetailPage(pageName: "Konfirmasi Reservasi"),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {},
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(15),
                          imageLoader(), // Gambar Gedung
                          const Gap(15),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Detail Informasi Gedung & Tanggal
                                TitleSubtitleDetailPage(
                                  title: widget.building.name!,
                                  subtitle: widget.building.description!,
                                  isTitle: true,
                                ),
                                TitleSubtitleDetailPage(
                                  title: "Fasilitas",
                                  subtitle: widget.building.facility!,
                                ),
                                TitleSubtitleDetailPage(
                                  title: "Kapasitas",
                                  subtitle:
                                  "${widget.building.capacity!.toString()} Orang",
                                ),
                                TitleSubtitleDetailPage(
                                  title: "Peraturan",
                                  subtitle: widget.building.rule!,
                                ),
                                TitleSubtitleDetailPage(
                                  title: "Status Gedung/Ruangan",
                                  subtitle: widget.building.status!,
                                ),
                                TitleSubtitleDetailPage(
                                  title: "Tanggal Pakai",
                                  subtitle:
                                  "${ParsingString().convertDate(widget.dateStart)} - ${ParsingString().convertDate(widget.dateEnd)}",
                                ),

                                // ==========================================
                                // Fitur Upload Bukti Pengajuan (Dokumen/Surat)
                                // ==========================================
                                const Gap(15),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 0),
                                  child: Text(
                                    "Bukti Pengajuan (Opsional)",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Gap(8),
                                GestureDetector(
                                  onTap: _pickProofImage, // Trigger pilih gambar
                                  child: Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade400),
                                    ),
                                    // Logic Preview: Tampilkan gambar jika ada, atau ikon 'Add' jika belum.
                                    child: _imageProof != null
                                        ? ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      child: Image.memory(
                                        _imageProof!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : const Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            size: 40, color: Colors.grey),
                                        Gap(8),
                                        Text(
                                          "Tap untuk upload dokumen",
                                          style: TextStyle(
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Gap(15),
                                // ==========================================

                                // Field Input Keterangan Tambahan
                                CustomTextFormField(
                                  fieldName: "Keterangan",
                                  controller: informationController,
                                  prefixIcon: Icons.description,
                                ),
                                const Gap(30),

                                // Tombol Submit
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ButtonPositive(
                                    name: "Reservasi Sekarang",
                                    function: () {
                                      // Konfirmasi ulang sebelum kirim data
                                      PopUp().whenDoSomething(
                                        context,
                                        "Ingin melakukan reservasi?",
                                        Icons.corporate_fare,
                                        createReservation(),
                                      );
                                    },
                                  ),
                                ),
                                const Gap(40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            // Indikator Loading saat proses upload/submit
            Center(
              child: BlocBuilder<ReservationBloc, ReservationState>(
                builder: (context, state) {
                  if (state is ReservationLoading) {
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