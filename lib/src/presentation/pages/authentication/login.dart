import '../../../data/repositories/repositories.dart'; // Untuk akses UserRepo
import '../../../data/utils/notification_services.dart'; // Untuk akses token FCM
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reservation_app/src/presentation/widgets/general/widget_custom_text_form_field.dart';

import '../../../data/bloc/authentication/authentication_bloc.dart';
import '../../utils/constant/constant.dart';
import '../../utils/routes/route_name.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// inisiasi controller untuk menangkap inputan user
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late AuthenticationBloc loginBloc;
  late String role;

  // Key ini penting untuk validasi form (cek kosong atau tidak) sebelum dikirim
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// Fungsi ini yang dipanggil saat tombol 'Masuk' ditekan.
  /// Gunanya untuk memicu event 'OnLogin' ke AuthenticationBloc.
  /// Data username dan password dari controller dikirim ke Bloc untuk diproses ke backend.
  loginButton() {
    loginBloc = context.read<AuthenticationBloc>();
    loginBloc.add(OnLogin(
      usernameController.text.toString(),
      passwordController.text.toString(),
    ));
  }

  @override
  void initState() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    // Wajib dispose controller biar gak memory leak pas pindah halaman
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener di sini fungsinya cuma buat mendengarkan perubahan state,
    // bukan buat ngerender UI (Logic Only). Cocok buat navigasi atau snackbar.
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) async {

        // === LOGIKA UPDATE TOKEN NOTIFIKASI ===
        // Kalau login berhasil (dapat role SuperAdmin, Admin, atau User),
        // saya langsung update Device Token (FCM) user tersebut ke database.
        // Gunanya supaya notifikasi reservasi masuk ke HP yang sedang dipakai login ini.
        if (state is IsSuperAdmin || state is IsAdmin || state is IsUser) {
          try {
            final token = await NotificationServices().getDeviceToken();
            final username = usernameController.text;

            if (token != null && username.isNotEmpty) {
              await UserRepo().updateUserFCMToken(username, token);
              if (kDebugMode) {
                print("✅ FCM Token berhasil di-update untuk: $username");
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print("❌ Gagal update token saat login: $e");
            }
          }
        }
        // ===========================

        // Cek mounted dulu untuk menghindari error 'use_build_context_synchronously'
        // kalau user tiba-tiba keluar aplikasi pas lagi loading.
        if (!context.mounted) return;

        // === LOGIKA NAVIGASI (ROUTING) ===
        // Di sini penentuan arah navigasi berdasarkan role yang didapat dari database.
        // Menggunakan GoRouter (context.goNamed) biar manajemen stack halamannya rapi.
        if (state is IsSuperAdmin) {
          context.goNamed(Routes().homeSuperAdmin);
        } else if (state is IsAdmin) {
          context.goNamed(Routes().homeAdmin);
        } else if (state is IsUser) {
          context.goNamed(Routes().home);
        }
      },
      child: Scaffold(
        // Pakai Stack supaya saya bisa menaruh loading indicator (overlay)
        // tepat di atas form login ketika proses verifikasi sedang berjalan.
        body: Stack(
          children: [
            Center(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Fitur tarik ke bawah, saat ini dikosongkan (Do Nothing)
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey, // Mengaitkan key validasi ke widget Form
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            imageIconApp,
                            height: 120,
                            width: 120,
                            scale: 1,
                            fit: BoxFit.fill,
                          ),
                          const Gap(10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Masuk",
                              style: GoogleFonts.openSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Gap(10),
                          // Custom Widget untuk input text biar kodenya lebih bersih (reusable)
                          CustomTextFormField(
                            fieldName: "Nama Pengguna",
                            controller: usernameController,
                            prefixIcon: Icons.person,
                          ),
                          CustomTextFormField(
                            fieldName: "Kata Sandi",
                            controller: passwordController,
                            prefixIcon: Icons.lock,
                          ),

                          // BlocBuilder ini khusus buat nampilin pesan error kalau login gagal (misal: password salah).
                          // Kenapa dipisah? Supaya yang di-rebuild cuma teks errornya aja, bukan se-halaman.
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: BlocBuilder<AuthenticationBloc,
                                AuthenticationState>(
                              builder: (context, state) {
                                if (state is LoginFailed) {
                                  return Text(
                                    state.error,
                                    style: const TextStyle(
                                        color: Colors.redAccent),
                                  );
                                } else {
                                  return const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: SizedBox(),
                                  );
                                }
                              },
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Validasi dulu: Pastikan form gak ada yang kosong.
                                  // Kalau valid, baru panggil fungsi loginButton().
                                  if (_formKey.currentState!.validate()) {
                                    loginButton();
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                splashColor: Colors.blue,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    "Masuk",
                                    style: GoogleFonts.openSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Ini layer loading yang muncul kalau state lagi 'LoginLoading'.
            // User jadi gak bisa klik apa-apa pas lagi muter (blocking UI).
            Center(
              child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (context, state) {
                  if (state is LoginLoading) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0x80FFFFFF), // Putih transparan
                      ),
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
    );
  }
}