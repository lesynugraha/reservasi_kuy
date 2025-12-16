import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:reservation_app/src/data/bloc/logout/logout_bloc.dart';
import 'package:reservation_app/src/data/utils/notification_services.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'src/data/bloc/authentication/authentication_bloc.dart';
import 'src/data/bloc/building/building_bloc.dart';
import 'src/data/bloc/extracurricular/extracurricular_bloc.dart';
import 'src/data/bloc/history/history_bloc.dart';
import 'src/data/bloc/register/register_bloc.dart';
import 'src/data/bloc/reservation/reservation_bloc.dart';
import 'src/data/bloc/reservation_building/reservation_building_bloc.dart';
import 'src/data/bloc/user/user_bloc.dart';
import 'src/data/repositories/repositories.dart';

void main() async {
  // Memastikan binding Flutter telah terinisialisasi sebelum menjalankan kode async (seperti Firebase).
  // Ini wajib dipanggil jika fungsi main() bersifat asynchronous.
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase berdasarkan platform (Android/iOS) menggunakan konfigurasi dari firebase_options.dart.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Memanggil service notifikasi di awal agar aplikasi siap menerima pesan FCM segera setelah dijalankan.
  await NotificationServices().initialMessaging();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan MultiBlocProvider di root widget (paling atas).
    // Tujuannya agar state dari Bloc-bloc ini bersifat global dan bisa diakses dari halaman mana saja (Dependency Injection).
    return MultiBlocProvider(
      providers: [
        // Setiap Bloc diinjeksi dengan 'Repositories()' agar mereka bisa mengakses data dari Firebase.
        BlocProvider(
          create: (context) => AuthenticationBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => RegisterBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => ReservationBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => BuildingBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => HistoryBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => UserBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) =>
              ExtracurricularBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) =>
              ReservationBuildingBloc(repositories: Repositories()),
        ),
        BlocProvider(
          create: (context) => LogoutBloc(repositories: Repositories()),
        ),
      ],
      // Masuk ke widget utama aplikasi (Apps) yang mengatur routing dan tema.
      child: const Apps(),
    );
  }
}

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
//   late Future<String> permissionStatusFuture;
//
//   var permGranted = "granted";
//   var permDenied = "denied";
//   var permUnknown = "unknown";
//   var permProvisional = "provisional";
//
//   @override
//   void initState() {
//     super.initState();
//     // set up the notification permissions class
//     // set up the future to fetch the notification data
//     permissionStatusFuture = getCheckNotificationPermStatus();
//     // With this, we will be able to check if the permission is granted or not
//     // when returning to the application
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   /// When the application has a resumed status, check for the permission
//   /// status
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       setState(() {
//         permissionStatusFuture = getCheckNotificationPermStatus();
//       });
//     }
//   }
//
//   /// Checks the notification permission status
//   Future<String> getCheckNotificationPermStatus() {
//     return NotificationPermissions.getNotificationPermissionStatus()
//         .then((status) {
//       switch (status) {
//         case PermissionStatus.denied:
//           return permDenied;
//         case PermissionStatus.granted:
//           return permGranted;
//         case PermissionStatus.unknown:
//           return permUnknown;
//         case PermissionStatus.provisional:
//           return permProvisional;
//         default:
//           return "";
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create: (context) => AuthenticationBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => RegisterBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => ReservationBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => BuildingBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => HistoryBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => UserBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) =>
//               ExtracurricularBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) =>
//               ReservationBuildingBloc(repositories: Repositories()),
//         ),
//         BlocProvider(
//           create: (context) => LogoutBloc(repositories: Repositories()),
//         ),
//       ],
//       child: const Apps(),
//     );
//   }
// }
