import 'package:flutter/material.dart';
import 'src/presentation/utils/routes/route_app.dart';

class Apps extends StatefulWidget {
  const Apps({super.key});

  @override
  State<Apps> createState() => _AppsState();
}

class _AppsState extends State<Apps> {
  @override
  Widget build(BuildContext context) {
    // Saya membungkus seluruh aplikasi dengan GestureDetector.
    // Tujuannya untuk 'Quality of Life' user: supaya kalau user tap di area kosong (di luar form), keyboard otomatis tertutup (unfocus).
    // Ini penting banget biar keyboard gak menutupi tombol submit.
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),

      // Menggunakan MaterialApp.router karena saya menerapkan sistem navigasi GoRouter (didefinisikan di 'routeApp').
      // Kelebihannya dibanding Navigator biasa adalah pengelolaan history page dan deep linking yang lebih terstruktur.
      child: MaterialApp.router(
        routerConfig: routeApp,

        // Mengatur tema global aplikasi. Saya set background scaffold jadi putih bersih (Hex FFFFFF)
        // agar konsisten di semua halaman tanpa perlu atur satu-satu.
        theme: ThemeData(scaffoldBackgroundColor: const Color(0xFFFFFFFF)),
      ),
    );
  }
}