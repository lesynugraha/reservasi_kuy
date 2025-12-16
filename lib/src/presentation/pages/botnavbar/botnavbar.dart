import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/bloc/authentication/authentication_bloc.dart';
import '../../utils/constant/constant.dart';
import 'icon_navbar.dart';

class BotNavBar extends StatefulWidget {
  // menggunakan StatefulNavigationShell dari GoRouter.
  // Ini komponen kuncinya, Gunanya untuk membuat 'Persistent Bottom Navigation'.
  // Jadi kalau user pindah tab (misal dari Home ke Gedung), state di halaman Home tidak hilang/reset.
  final StatefulNavigationShell navigationShell;

  const BotNavBar({required this.navigationShell, super.key});

  @override
  State<BotNavBar> createState() => _BotNavBarState();
}

class _BotNavBarState extends State<BotNavBar> {

  // Fungsi navigasi untuk perpindahan tab.
  // Saya menggunakan 'goBranch' supaya GoRouter tahu branch mana yang harus diaktifkan
  // tanpa menumpuk halaman baru di stack (memory efficient).
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      // Kalau user tap icon tab yang sedang aktif, dia akan kembali ke root (awal) tab tersebut.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  // === DEFINISI ITEM NAVIGASI BERDASARKAN ROLE ===
  // memisahkan list menu ini supaya codingannya bersih dan mudah dimaintain.

  // 1. Menu untuk User (Siswa/Organisasi) - Akses Penuh ke fitur reservasi
  final List<BottomNavigationBarItem> _itemBotNavBarUser = [
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: homeIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: homeActiveIcon, color: Colors.blueAccent),
      label: "Home",
    ),
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: buildingIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: buildingActiveIcon, color: Colors.blueAccent),
      label: "Gedung",
    ),
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: reservationIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: reservationActiveIcon, color: Colors.blueAccent),
      label: "Reservasi",
    ),
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: historyIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: historyActiveIcon, color: Colors.blueAccent),
      label: "Riwayat",
    ),
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: profileIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: profileActiveIcon, color: Colors.blueAccent),
      label: "Saya",
    ),
  ];

  // 2. Menu untuk Admin (Supervisor Sekolah) - Fokus monitoring laporan
  final List<BottomNavigationBarItem> _iconBotNavBarAdmin = [
    // Index 0 di Shell Admin = Home
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: homeIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: homeActiveIcon, color: Colors.blueAccent),
      label: "Home",
    ),
    // Index 1 di Shell Admin = Building (Manajemen Gedung)
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: buildingIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: buildingActiveIcon, color: Colors.blueAccent),
      label: "Gedung",
    ),
    // Index 2 di Shell Admin = Report (Laporan aktivitas)
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: historyIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: historyActiveIcon, color: Colors.blueAccent),
      label: "Laporan",
    ),
    // Index 3 di Shell Admin = Profile
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: profileIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: profileActiveIcon, color: Colors.blueAccent),
      label: "Saya",
    ),
  ];

  // 3. Menu untuk SuperAdmin - Hanya manajemen user
  final List<BottomNavigationBarItem> _iconBotNavBarSuperAdmin = [
    // Index 0 di Shell SuperAdmin = Home
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: homeIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: homeActiveIcon, color: Colors.blueAccent),
      label: "Home",
    ),
    // Index 1 di Shell SuperAdmin = Profile
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: profileIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: profileActiveIcon, color: Colors.blueAccent),
      label: "Saya",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Mengambil index halaman saat ini langsung dari Shell GoRouter biar sinkron.
    final int currentIndex = widget.navigationShell.currentIndex;

    // Menggunakan BlocBuilder untuk merender BottomNavBar yang berbeda sesuai Role user yang login.
    // Ini memastikan user tidak bisa melihat menu yang bukan hak aksesnya (Security by UI).
    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state is IsSuperAdmin) {
          return Scaffold(
            // Body-nya adalah navigationShell, bukan widget halaman biasa.
            // Ini supaya konten halaman berganti sesuai tab yang dipilih.
            body: widget.navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              iconSize: 22,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: _goBranch,
              items: _iconBotNavBarSuperAdmin,
            ),
          );
        } else if (state is IsAdmin) {
          return Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              iconSize: 22,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: _goBranch,
              items: _iconBotNavBarAdmin,
            ),
          );
        }
        if (state is IsUser) {
          return Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              iconSize: 22,
              type: BottomNavigationBarType.fixed,
              currentIndex: currentIndex,
              onTap: _goBranch, // Fungsi pindah halaman dipanggil di sini
              items: _itemBotNavBarUser,
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}