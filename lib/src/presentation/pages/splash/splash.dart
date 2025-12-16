import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/bloc/authentication/authentication_bloc.dart';
import '../../utils/constant/constant.dart';
import '../../utils/routes/route_name.dart';

// Halaman Splash Screen yang muncul pertama kali saat aplikasi dibuka.
// Fungsinya untuk branding (menampilkan logo) dan inisialisasi awal (cek status login).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Timer _timer;
  late AuthenticationBloc _loginBloc;

  // Fungsi timer untuk menahan tampilan splash selama beberapa detik
  // agar logo sempat terlihat oleh user sebelum pindah halaman.
  _splashScreen() {
    _timer = Timer(
      const Duration(seconds: 2, milliseconds: 5), // Durasi splash screen
          () {
        _checkIsLogin(); // Setelah timer habis, cek status login
      },
    );
  }

  // Memicu event 'InitialLogin' di AuthenticationBloc.
  // Bloc akan mengecek apakah user masih memiliki sesi login aktif di Shared Preferences / Firebase Auth.
  _checkIsLogin() {
    _loginBloc = context.read<AuthenticationBloc>();
    _loginBloc.add(InitialLogin());
  }

  @override
  void initState() {
    _splashScreen(); // Mulai timer saat widget dibuat
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel(); // Bersihkan timer agar tidak memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener mendengarkan hasil cek status login dari Bloc.
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        // Navigasi otomatis berdasarkan Role yang terdeteksi:
        if (state is IsSuperAdmin) {
          context.goNamed(Routes().homeSuperAdmin);
        } else if (state is IsAdmin) {
          context.goNamed(Routes().homeAdmin);
        } else if (state is IsUser) {
          context.goNamed(Routes().home);
        } else if (state is UnAuthenticated) {
          // Jika belum login atau sesi habis, arahkan ke halaman Login
          context.goNamed(Routes().login);
        } else {
          // Default fallback ke halaman Login
          context.goNamed(Routes().login);
        }
      },
      child: Scaffold(
        // Tampilan UI sederhana: Logo di tengah layar
        body: Center(
          child: Image.asset(imageSplash), // Menggunakan aset gambar dari konstanta
        ),
      ),
    );
  }
}