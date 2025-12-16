import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/bloc/register/register_bloc.dart';
import '../../../data/model/user_model.dart';
import '../../widgets/general/button_positive.dart';
import '../../widgets/general/header_detail_page.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_loading.dart';
import '../../widgets/general/widget_custom_text_form_field.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';
import 'widget_profile_text_field.dart';

// Halaman untuk mengedit profil pengguna.
// Digunakan oleh SuperAdmin untuk mengedit data Supervisor/User.
class EditUserPage extends StatefulWidget {
  const EditUserPage({
    super.key,
    required this.userModel, // Menerima data user yang akan diedit
  });

  final UserModel userModel;

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  // Controller untuk setiap field data.
  late TextEditingController idController;
  late TextEditingController agencyController;
  late TextEditingController usernameController;
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  // Controller sementara untuk fitur edit khusus (seperti username) via popup.
  late TextEditingController temporaryController;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyEdit = GlobalKey<FormState>();
  late RegisterBloc registerBloc;

  /// Fungsi utama untuk menyimpan perubahan data user secara keseluruhan.
  /// Mengirim event 'EditUserAdmin' ke Bloc.
  editUser() {
    return () {
      registerBloc = context.read<RegisterBloc>();
      registerBloc.add(EditUserAdmin(
        idController.text,
        agencyController.text,
        usernameController.text,
        passwordController.text,
        fullNameController.text,
        emailController.text,
        phoneController.text,
      ));
    };
  }

  /// Fungsi khusus untuk mengganti username.
  /// Username perlu penanganan khusus (seperti cek ketersediaan/duplikasi di database) sebelum disimpan.
  changeUsername() {
    registerBloc = context.read<RegisterBloc>();
    registerBloc.add(ChangeUsername(
      idController.text,
      usernameController.text,
    ));
  }

  /// Popup dialog untuk edit field spesifik (dalam hal ini Username).
  /// TODO: Ke depannya bisa dibuat widget reusable agar tidak hardcoded di sini.
  popUpEditUsername(
      String fieldName,
      TextEditingController controller,
      IconData prefixIcon,
      ) {
    // Isi controller sementara dengan data saat ini agar user tidak perlu ketik ulang.
    temporaryController.text = controller.text;

    return showDialog(
      context: context,
      barrierDismissible: false, // Dialog tidak bisa ditutup dengan klik di luar area
      builder: (context) {
        return BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            // Jika sukses ganti username, tutup dialog.
            if (state is ChangeUsernameSuccess) {
              Navigator.of(context).pop();
            }
          },
          child: AlertDialog(
            insetPadding: const EdgeInsets.all(10),
            title: Center(
              child: Text(
                "Edit $fieldName",
                style: GoogleFonts.openSans(),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 90,
              child: Form(
                key: formKeyEdit,
                child: Column(
                  children: [
                    CustomTextFormField(
                      fieldName: fieldName,
                      controller: temporaryController,
                      prefixIcon: prefixIcon,
                    ),

                    // Menampilkan pesan error khusus di dalam dialog jika username sudah ada.
                    BlocBuilder<RegisterBloc, RegisterState>(
                      builder: (context, state) {
                        if (state is ChangeUsernameFailed) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                state.error,
                                style: GoogleFonts.openSans(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          );
                        } else if (state is RegisterLoading) {
                          return const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Tombol Batal
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          width: 1,
                          color: Colors.blueAccent,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Tombol Simpan (di dalam popup)
                  InkWell(
                    onTap: () {
                      if (formKeyEdit.currentState!.validate()) {
                        // Update controller utama dengan nilai dari controller sementara
                        controller.text = temporaryController.text;
                        changeUsername(); // Jalankan logika cek username
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blueAccent),
                      child: const Center(
                        child: Text(
                          'Simpan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    // Pre-filling data form dengan data user yang diterima dari parameter.
    // Memudahkan user melakukan edit tanpa harus mengisi ulang semua field.
    idController = TextEditingController(text: widget.userModel.id);
    agencyController = TextEditingController(text: widget.userModel.agency);
    usernameController = TextEditingController(text: widget.userModel.username);
    fullNameController = TextEditingController(text: widget.userModel.fullName);
    emailController = TextEditingController(text: widget.userModel.email);
    phoneController = TextEditingController(text: widget.userModel.phone);
    passwordController = TextEditingController(text: widget.userModel.password);
    temporaryController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // Membersihkan semua controller.
    idController.dispose();
    agencyController.dispose();
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    temporaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener mendengarkan hasil akhir penyimpanan data (EditSuccess).
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is EditSuccess) {
          PopUp().whenSuccessDoSomething(
            context,
            "Berhasil melakukan perubahan",
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
                const HeaderDetailPage(
                  pageName: "Edit User",
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {},
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        child: Form(
                          key: formKey, // Kunci validasi form utama
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(10),
                              const CustomTitleTextFormField(
                                subtitle: "Username",
                              ),
                              // Field Username bersifat spesial: Editnya lewat Popup (isEdit: true).
                              // Ini mencegah user asal ganti username tanpa validasi ketersediaan.
                              CustomProfileTextFormField(
                                fieldName: "Username",
                                controller: usernameController,
                                prefixIcon: Icons.person,
                                isEdit: true,
                                function: () {
                                  // Menggunakan SchedulerBinding agar popup muncul setelah frame selesai dirender.
                                  SchedulerBinding.instance
                                      .addPostFrameCallback((_) {
                                    popUpEditUsername(
                                      "Username",
                                      usernameController,
                                      Icons.person,
                                    );
                                  });
                                },
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Instansi",
                              ),
                              // Field Instansi (Read-only jika role tertentu, diatur di widget CustomTextFormField)
                              CustomTextFormField(
                                fieldName: "Instansi",
                                controller: agencyController,
                                prefixIcon: Icons.corporate_fare,
                                role: widget.userModel.role,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Nama",
                              ),
                              CustomTextFormField(
                                fieldName: "Nama Lengkap",
                                controller: fullNameController,
                                prefixIcon: Icons.person,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "E-Mail",
                              ),
                              CustomTextFormField(
                                fieldName: "E-Mail",
                                controller: emailController,
                                prefixIcon: Icons.email,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Nomor Telepon",
                              ),
                              CustomTextFormField(
                                fieldName: "Nomor Telepon",
                                controller: phoneController,
                                prefixIcon: Icons.phone_android,
                              ),
                              const CustomTitleTextFormField(
                                subtitle: "Kata Sandi",
                              ),
                              CustomTextFormField(
                                fieldName: "Password",
                                controller: passwordController,
                                prefixIcon: Icons.lock,
                              ),
                              const Gap(20),
                              // Tombol Simpan Perubahan Utama
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ButtonPositive(
                                  name: "Simpan Perubahan",
                                  function: () {
                                    if (formKey.currentState!.validate()) {
                                      PopUp().whenDoSomething(
                                        context,
                                        "Simpan perubahan user?",
                                        Icons.person,
                                        editUser(), // Panggil fungsi editUser
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
            // Indikator Loading Global (memblokir seluruh layar saat simpan data)
            BlocBuilder<RegisterBloc, RegisterState>(
              builder: (context, state) {
                if (state is RegisterLoading) {
                  return const CustomLoading();
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}