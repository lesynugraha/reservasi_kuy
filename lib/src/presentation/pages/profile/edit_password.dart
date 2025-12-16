import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/presentation/widgets/general/pop_up.dart';
import 'package:reservation_app/src/presentation/widgets/general/widget_custom_loading.dart';

import '../../../data/bloc/user/user_bloc.dart';
import '../../../data/model/user_model.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';
import '../../widgets/general/widget_custom_text_form_field.dart';

class EditPasswordPage extends StatefulWidget {
  // Wajib menerima data 'userModel' karena kita butuh ID dan Username
  // untuk dikirim ke API/Firebase saat request ganti password.
  const EditPasswordPage({
    super.key,
    required this.userModel,
  });

  final UserModel userModel;

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  // Controller untuk menangkap inputan user
  late TextEditingController oldPasswordController; // Sandi lama
  late TextEditingController new1PasswordController; // Sandi baru
  late TextEditingController new2PasswordController; // Konfirmasi sandi baru

  late UserBloc userBloc;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    oldPasswordController = TextEditingController();
    new1PasswordController = TextEditingController();
    new2PasswordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // Membersihkan controller dari memori saat halaman ditutup
    oldPasswordController.dispose();
    new1PasswordController.dispose();
    new2PasswordController.dispose();
    super.dispose();
  }

  /// Fungsi logika utama ganti password.
  /// Menggunakan 'UserBloc' dengan event 'EditPassword'.
  editPassword() {
    return () {
      userBloc = context.read<UserBloc>();
      userBloc.add(
        EditPassword(
          widget.userModel.id!,          // ID User (Primary Key)
          widget.userModel.username!,    // Username (Identifikasi)
          oldPasswordController.text,    // Password Lama (Verifikasi keamanan)
          new1PasswordController.text,   // Password Baru (Data yang diupdate)
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener mendengarkan hasil dari UserBloc.
    // Jika sukses -> Tampilkan popup sukses.
    // Jika gagal -> Pesan error akan ditampilkan di text bawah form.
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is EditPasswordSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil mengubah password",
            Icons.check_circle,
            true, // true artinya tutup halaman ini setelah sukses
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderDetailPage(pageName: "Ubah Kata Sandi"),
                // RefreshIndicator untuk UX pull-to-refresh (opsional di sini)
                RefreshIndicator(
                  onRefresh: () async {},
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Form(
                        key: formKey, // Key untuk validasi input
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Gap(20),
                            // Field: Kata Sandi Lama
                            const CustomTitleTextFormField(subtitle: "Kata Sandi Lama"),
                            CustomTextFormField(
                              fieldName: "Kata Sandi Lama",
                              controller: oldPasswordController,
                              prefixIcon: Icons.lock,
                            ),

                            // Field: Kata Sandi Baru
                            const CustomTitleTextFormField(subtitle: "Kata Sandi Baru"),
                            CustomTextFormField(
                              fieldName: "Kata Sandi Baru",
                              controller: new1PasswordController,
                              prefixIcon: Icons.lock,
                            ),

                            // Field: Konfirmasi Kata Sandi Baru
                            // controller2 digunakan di dalam widget CustomTextFormField untuk validasi
                            // kecocokan antara password baru dan konfirmasinya.
                            const CustomTitleTextFormField(
                                subtitle: "Konfirmasi Kata Sandi Baru"),
                            CustomTextFormField(
                              fieldName: "Konfirmasi Kata Sandi Baru",
                              controller: new2PasswordController,
                              controller2: new1PasswordController,
                              prefixIcon: Icons.lock,
                            ),

                            const Gap(20),

                            // Menampilkan pesan Error jika Bloc mereturn state gagal
                            // (Misal: Password lama salah).
                            BlocBuilder<UserBloc, UserState>(
                              builder: (context, state) {
                                if (state is EditPasswordFailed) {
                                  return Center(
                                    child: Text(
                                      state.error,
                                      style: GoogleFonts.openSans(
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox();
                                }
                              },
                            ),
                            const Gap(20),

                            // Tombol Simpan
                            Align(
                              alignment: Alignment.bottomRight,
                              child: ButtonPositive(
                                name: "Simpan Perubahan",
                                function: () {
                                  // Validasi form (cek kosong / tidak cocok)
                                  if (formKey.currentState!.validate()) {
                                    PopUp().whenDoSomething(
                                      context,
                                      "Yakin ingin mengganti kata sandi?",
                                      Icons.lock,
                                      editPassword(), // Panggil fungsi editPassword
                                    );
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),

            // Loading Overlay
            // Muncul di tengah layar saat UserBloc sedang memproses data (UserLoading)
            Center(
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UserLoading) {
                    return const CustomLoading();
                  } else {
                    return const SizedBox();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}