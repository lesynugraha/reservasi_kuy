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
  /// inisiasi data
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  late AuthenticationBloc loginBloc;
  late String role;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// fungsi untuk login
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
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) async {
        // === LOGIKA UPDATE TOKEN ===
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

        // [PENTING] Cek apakah halaman masih ada sebelum pindah
        // Ini menghilangkan warning 'use_build_context_synchronously'
        if (!context.mounted) return;

        // === LOGIKA NAVIGASI ===
        if (state is IsSuperAdmin) {
          context.goNamed(Routes().homeSuperAdmin);
        } else if (state is IsAdmin) {
          context.goNamed(Routes().homeAdmin);
        } else if (state is IsUser) {
          context.goNamed(Routes().home);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: RefreshIndicator(
                onRefresh: () async {
                  //Do Nothing
                },
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
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
            Center(
              child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
                builder: (context, state) {
                  if (state is LoginLoading) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0x80FFFFFF),
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
