import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/bloc/authentication/authentication_bloc.dart';
import '../../utils/constant/constant.dart';
import 'icon_navbar.dart';

class BotNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BotNavBar({required this.navigationShell, super.key});

  @override
  State<BotNavBar> createState() => _BotNavBarState();
}

class _BotNavBarState extends State<BotNavBar> {

  // Fungsi navigasi sederhana: Langsung gunakan index asli
  // Karena setiap Role punya Shell sendiri, index-nya sudah pasti 1:1
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

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

  final List<BottomNavigationBarItem> _iconBotNavBarAdmin = [
    // Index 0 di Shell Admin = Home
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: homeIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: homeActiveIcon, color: Colors.blueAccent),
      label: "Home",
    ),
    // Index 1 di Shell Admin = Building
    const BottomNavigationBarItem(
      icon: IconNavBar(iconPath: buildingIcon, color: Colors.transparent),
      activeIcon: IconNavBar(iconPath: buildingActiveIcon, color: Colors.blueAccent),
      label: "Gedung",
    ),
    // Index 2 di Shell Admin = Report (History)
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
    // Ambil index langsung dari Shell yang sedang aktif
    final int currentIndex = widget.navigationShell.currentIndex;

    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, state) {
        if (state is IsSuperAdmin) {
          return Scaffold(
            body: widget.navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              iconSize: 22,
              type: BottomNavigationBarType.fixed,
              // Index shell SuperAdmin pasti 0 atau 1. Aman.
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
              // Index shell Admin pasti 0, 1, 2, atau 3. Aman.
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
              // Index shell User pasti 0 s.d 4. Aman.
              currentIndex: currentIndex,
              onTap: _goBranch,
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