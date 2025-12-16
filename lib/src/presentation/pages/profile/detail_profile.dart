import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/model/user_model.dart';
import '../../utils/constant/constant.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';
import 'widget_profile_text_field.dart';

// Halaman ini digunakan untuk melihat detail informasi profil (khususnya untuk SuperAdmin melihat detail Supervisor).
// Menggunakan StatefulWidget karena memerlukan inisialisasi TextController di awal (initState).
class DetailProfilePage extends StatefulWidget {
  const DetailProfilePage({super.key, required this.userModel});

  // Menerima data user secara utuh dari halaman sebelumnya (Data Passing).
  // Menghindari request database berulang untuk efisiensi.
  final UserModel userModel;

  @override
  State<DetailProfilePage> createState() => _DetailProfilePageState();
}

class _DetailProfilePageState extends State<DetailProfilePage> {
  // Controller digunakan untuk menampung teks yang akan ditampilkan di field.
  // Meskipun ini halaman detail (biasanya read-only), penggunaan controller memudahkan jika nanti fitur ini dikembangkan menjadi edit langsung.
  late TextEditingController usernameController;
  late TextEditingController agencyController;
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  // Fungsi untuk menangani tampilan foto profil.
  // Logika: Jika URL kosong -> Tampilkan aset lokal default.
  // Jika ada URL -> Gunakan CachedNetworkImage untuk menyimpan gambar di cache lokal (hemat bandwidth).
  imageLoader() {
    if (widget.userModel.image == "") {
      return ClipOval(
        child: Image.asset(
          assetsDefaultProfilePicture,
          height: 150,
          width: 150,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return ClipOval(
        child: CachedNetworkImage(
          height: 150,
          width: 150,
          imageUrl: widget.userModel.image!,
          fit: BoxFit.cover,
          placeholder: (context, url) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorWidget: (context, url, error) {
            return Image.asset(
              assetsDefaultProfilePicture,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            );
          },
        ),
      );
    }
  }

  @override
  void initState() {
    // Inisialisasi controller dengan data yang dibawa dari widget.userModel.
    // Dilakukan di initState agar data langsung muncul saat halaman pertama kali dirender.
    usernameController = TextEditingController(text: widget.userModel.username);
    agencyController = TextEditingController(text: widget.userModel.agency);
    fullNameController = TextEditingController(text: widget.userModel.fullName);
    phoneController = TextEditingController(text: widget.userModel.phone);
    emailController = TextEditingController(text: widget.userModel.email);
    passwordController = TextEditingController(text: widget.userModel.password);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            // Header halaman detail
            HeaderDetailPage(pageName: widget.userModel.fullName!),
            Expanded(
              child: RefreshIndicator(
                // RefreshIndicator disediakan untuk menjaga konsistensi UX (pull-to-refresh),
                // meskipun saat ini belum ada logika refresh data khusus di sini.
                onRefresh: () async {},
                child: SingleChildScrollView(
                  // Physics AlwaysScrollable diperlukan agar halaman bisa discroll (bouncy effect)
                  // meskipun kontennya pendek, mencegah kesan aplikasi macet.
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const Gap(30),
                      imageLoader(), // Menampilkan foto profil
                      const Gap(20),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Menampilkan data menggunakan widget custom field
                            const CustomTitleTextFormField(subtitle: "Username"),
                            CustomProfileTextFormField(
                              fieldName: "Username",
                              controller: usernameController,
                              prefixIcon: Icons.person,
                            ),
                            const CustomTitleTextFormField(subtitle: "Instansi"),
                            CustomProfileTextFormField(
                              fieldName: "Instansi",
                              controller: agencyController,
                              prefixIcon: Icons.corporate_fare,
                            ),
                            const CustomTitleTextFormField(
                                subtitle: "Nama Lengkap"),
                            CustomProfileTextFormField(
                              fieldName: "Nama Lengkap",
                              controller: fullNameController,
                              prefixIcon: Icons.contact_mail,
                            ),
                            const CustomTitleTextFormField(subtitle: "E-Mail"),
                            CustomProfileTextFormField(
                              fieldName: "E-Mail",
                              controller: emailController,
                              prefixIcon: Icons.email,
                            ),
                            const CustomTitleTextFormField(
                                subtitle: "Nomor Telepon"),
                            CustomProfileTextFormField(
                              fieldName: "Nomor Telepon",
                              controller: phoneController,
                              prefixIcon: Icons.phone_android,
                            ),
                            const CustomTitleTextFormField(subtitle: "Password"),
                            // Field password bisa di-toggle visibility-nya (lihat icon mata)
                            CustomProfileTextFormField(
                              fieldName: "Password",
                              controller: passwordController,
                              prefixIcon: Icons.lock,
                              canVisible: true,
                            ),
                            const Gap(30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}