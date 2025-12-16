import 'package:flutter/material.dart';
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

class AddUserPage extends StatefulWidget {
  // Widget ini bersifat polimorfik (bisa dipakai oleh dua role berbeda).
  // 1. Super Admin pakai ini untuk tambah Supervisor Sekolah.
  // 2. Supervisor Sekolah pakai ini untuk tambah Siswa/User.
  const AddUserPage({
    super.key,
    required this.userModel, // Data user yang sedang login (untuk pengecekan role)
  });

  final UserModel userModel;

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  late TextEditingController agencyController;
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late TextEditingController fullNameController;
  late TextEditingController roleController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late RegisterBloc registerBloc;

  /// Fungsi untuk mengirim event registrasi ke Bloc.
  /// Parameter 'role' menentukan level akses user yang baru dibuat.
  register(String role) {
    return () {
      registerBloc = context.read<RegisterBloc>();
      registerBloc.add(
        Register(
          agencyController.text,
          usernameController.text,
          passwordController.text,
          fullNameController.text,
          role,
        ),
      );
    };
  }

  @override
  void initState() {
    // Jika yang login adalah Supervisor (Admin), field agency otomatis terisi sesuai sekolahnya.
    agencyController = TextEditingController(text: widget.userModel.agency);
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    fullNameController = TextEditingController();
    roleController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    agencyController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          PopUp().whenSuccessDoSomething(
            context, "User berhasil ditambahkan", Icons.check_circle, true,);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderDetailPage(
                  pageName: "Tambah User",
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
                          key: formKey, // Kunci validasi form
                          child: contentByRole(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Indikator loading saat proses registrasi ke backend
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

  // Menentukan tampilan form berdasarkan siapa yang sedang login.
  contentByRole() {
    // Jika yang login adalah Supervisor (Role 1), dia tidak boleh mengubah nama instansi/sekolah.
    // Dia hanya bisa menambahkan siswa untuk sekolahnya sendiri.
    if (widget.userModel.role == "1") {
      agencyController = TextEditingController(
        text: widget.userModel.agency!,
      );
    }
    return adminContent();
  }

  // Tampilan Form Input
  Column adminContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(10),
        const CustomTitleTextFormField(subtitle: "Nama Lengkap"),
        CustomTextFormField(
          fieldName: "Nama Lengkap",
          controller: fullNameController,
          prefixIcon: Icons.contact_mail,
        ),
        const Gap(10),
        const CustomTitleTextFormField(subtitle: "Username"),
        CustomTextFormField(
          fieldName: "Username",
          controller: usernameController,
          prefixIcon: Icons.person,
        ),
        const Gap(10),
        const CustomTitleTextFormField(subtitle: "Password"),
        CustomTextFormField(
          fieldName: "Password",
          controller: passwordController,
          prefixIcon: Icons.lock,
        ),
        const Gap(10),
        const CustomTitleTextFormField(subtitle: "Instansi"),
        // Field Instansi akan Read-Only jika widget.userModel.role == "1" (lihat logika di CustomTextFormField)
        CustomTextFormField(
          fieldName: "Instansi",
          controller: agencyController,
          prefixIcon: Icons.corporate_fare,
          role: widget.userModel.role,
        ),
        const Gap(20),

        // Menampilkan Error Register jika ada (misal username sudah dipakai)
        BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            if (state is RegisterFailed) {
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

        // Tombol Submit
        Align(
          alignment: Alignment.bottomRight,
          child: ButtonPositive(
            name: "Tambah User",
            function: () {
              if (formKey.currentState!.validate()) {
                // Logika Hierarki Penambahan User:
                // Jika SuperAdmin (0) -> Tambah Supervisor (1).
                // Jika Supervisor (1) -> Tambah User Biasa (2).
                if (widget.userModel.role == "0") {
                  PopUp().whenDoSomething(
                    context,
                    "Tambah user?",
                    Icons.person,
                    register("1"),
                  );
                } else {
                  PopUp().whenDoSomething(
                    context,
                    "Tambah user?",
                    Icons.person,
                    register("2"),
                  );
                }
              }
            },
          ),
        ),
        const Gap(30),
      ],
    );
  }
}