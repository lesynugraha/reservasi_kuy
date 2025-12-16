import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reservation_app/src/data/bloc/building/building_bloc.dart';
import 'package:reservation_app/src/data/bloc/user/user_bloc.dart';
import 'package:reservation_app/src/presentation/pages/profile/detail_profile.dart';
import 'package:reservation_app/src/presentation/pages/profile/edit_password.dart';
import 'package:reservation_app/src/presentation/pages/profile/profile_picture_full_screen.dart';

import '../../../data/bloc/extracurricular/extracurricular_bloc.dart';
import '../../../data/bloc/register/register_bloc.dart';
import '../../../data/model/building_model.dart';
import '../../../data/model/extracurricular_model.dart';
import '../../../data/model/user_model.dart';
import '../../pages/authentication/login.dart';
import '../../pages/botnavbar/botnavbar.dart';
import '../../pages/building/add_building.dart';
import '../../pages/building/page_building.dart';
import '../../pages/building/detail_building.dart';
import '../../pages/building/edit_building.dart';
import '../../pages/extracurricular/add_extracurricular.dart';
import '../../pages/extracurricular/detail_extracurricular.dart';
import '../../pages/extracurricular/edit_extracurricular.dart';
import '../../pages/history/history.dart';
import '../../pages/home/home.dart';
import '../../pages/profile/page_add_user.dart';
import '../../pages/profile/page_edit_user.dart';
import '../../pages/profile/page_profile.dart';
import '../../pages/reservation/confirm_reservation.dart';
import '../../pages/reservation/reservation.dart';
import '../../pages/splash/splash.dart';
import 'route_name.dart';

// ============================================================================
// KONFIGURASI NAVIGATOR KEY
// ============================================================================
// GlobalKey ini penting agar setiap tab pada Bottom Navigation Bar memiliki
// state navigatornya sendiri. Artinya, jika user masuk dalam ke menu di Tab A,
// lalu pindah ke Tab B, saat kembali ke Tab A posisinya masih sama (tidak reset).

// Keys untuk Role: User
final _navigatorHome = GlobalKey<NavigatorState>();
final _navigatorBuilding = GlobalKey<NavigatorState>();
final _navigatorReservation = GlobalKey<NavigatorState>();
final _navigatorHistory = GlobalKey<NavigatorState>();
final _navigatorProfile = GlobalKey<NavigatorState>();

// Keys untuk Role: Admin (Supervisor)
final _navigatorHomeAdmin = GlobalKey<NavigatorState>();
final _navigatorBuildingAdmin = GlobalKey<NavigatorState>();
final _navigatorReportAdmin = GlobalKey<NavigatorState>();
final _navigatorProfileAdmin = GlobalKey<NavigatorState>();

// Keys untuk Role: Super Admin
final _navigatorHomeSuperAdmin = GlobalKey<NavigatorState>();
final _navigatorProfileSuperAdmin = GlobalKey<NavigatorState>();

// ============================================================================
// DEFINISI ROUTING UTAMA (GoRouter)
// ============================================================================
final GoRouter routeApp = GoRouter(
  routes: <RouteBase>[

    // --- RUTE UMUM (Tanpa Bottom Nav Bar) ---
    // Rute ini berada di level paling atas (root), sehingga ketika dibuka,
    // Bottom Navigation Bar akan tertutup/hilang.

    /// Halaman pertama kali aplikasi dibuka (Splash Screen)
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    /// Halaman Login
    GoRoute(
      path: '/login',
      name: Routes().login,
      builder: (context, state) => const LoginPage(),
    ),

    /// Halaman Edit Password
    GoRoute(
      path: '/editPassword',
      name: Routes().editPassword,
      // onExit: Logic untuk refresh data saat user menekan tombol back.
      // Di sini kita memanggil UserBloc untuk mengambil data user terbaru.
      onExit: (context, state) {
        BlocProvider.of<UserBloc>(context).add(GetUserLoggedIn());
        return true; // true artinya boleh keluar dari halaman ini
      },
      builder: (context, state) {
        // Mengambil data object UserModel yang dikirim dari halaman sebelumnya
        return EditPasswordPage(
          userModel: state.extra as UserModel,
        );
      },
    ),

    /// Halaman Detail Gedung
    GoRoute(
      path: '/detailBuilding',
      name: Routes().detailBuilding,
      builder: (context, state) {
        // Menerima parameter object BuildingModel
        return DetailBuilding(
          building: state.extra as BuildingModel,
        );
      },
    ),

    /// Halaman Detail Ekstrakurikuler
    GoRoute(
      path: '/detailExtracurricular',
      name: Routes().detailExtracurricular,
      builder: (context, state) {
        return DetailExtracurricularPage(
          extracurricular: state.extra as ExtracurricularModel,
        );
      },
    ),

    /// Halaman Foto Profil Full Screen
    GoRoute(
      path: '/profilePictureFullScreen',
      name: Routes().profilePictureFullScreen,
      builder: (context, state) {
        return ProfilePictureFullScreen(
          user: state.extra as UserModel,
        );
      },
    ),

    // ========================================================================
    // STRUKTUR BOTTOM NAVIGATION BAR (SHELL ROUTE)
    // ========================================================================
    // StatefulShellRoute digunakan agar Bottom Navigation Bar tetap muncul
    // dan menjaga state (posisi scroll/halaman) dari setiap tab.

    /// 1. Navigation Bottom Bar untuk USER
    StatefulShellRoute.indexedStack(
      // Builder ini membungkus halaman-halaman di bawahnya dengan BotNavBar
      builder: (context, state, navigationShell) {
        return BotNavBar(
          navigationShell: navigationShell,
        );
      },
      branches: <StatefulShellBranch>[
        // Tab 1: Home
        StatefulShellBranch(
          navigatorKey: _navigatorHome,
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              name: Routes().home,
              builder: (context, state) {
                return const HomePage();
              },
            ),
          ],
        ),
        // Tab 2: Building (Daftar Gedung)
        StatefulShellBranch(
          navigatorKey: _navigatorBuilding,
          routes: <RouteBase>[
            GoRoute(
              path: '/building',
              name: Routes().building,
              builder: (context, state) {
                return const BuildingPage();
              },
            ),
          ],
        ),
        // Tab 3: Reservation (Peminjaman)
        StatefulShellBranch(
          navigatorKey: _navigatorReservation,
          routes: <RouteBase>[
            GoRoute(
                path: '/reservation',
                name: Routes().reservation,
                builder: (context, state) {
                  return const ReservationPage();
                },
                // Sub-route: Konfirmasi Reservasi
                routes: [
                  GoRoute(
                    path: 'confirmReservation',
                    name: Routes().confirmReservation,
                    builder: (context, state) {
                      // Mengambil parameter building (object) dan query params (string tanggal)
                      // Contoh URL: /reservation/confirmReservation?dateStart=2025-12-01&dateEnd=...
                      return ConfirmReservationPage(
                        building: state.extra as BuildingModel,
                        dateStart:
                        state.uri.queryParameters["dateStart"] as String,
                        dateEnd: state.uri.queryParameters["dateEnd"] as String,
                      );
                    },
                  )
                ]),
          ],
        ),
        // Tab 4: History (Riwayat)
        StatefulShellBranch(
          navigatorKey: _navigatorHistory,
          routes: <RouteBase>[
            GoRoute(
              path: '/history',
              name: Routes().history,
              builder: (context, state) {
                return const HistoryPage();
              },
            ),
          ],
        ),
        // Tab 5: Profile
        StatefulShellBranch(
          navigatorKey: _navigatorProfile,
          routes: <RouteBase>[
            GoRoute(
              path: '/profile',
              name: Routes().profile,
              builder: (context, state) {
                return const ProfilePage();
              },
            ),
          ],
        ),
      ],
    ),

    /// 2. Navigation Bottom Bar untuk ADMIN (Supervisor)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BotNavBar(
          navigationShell: navigationShell,
        );
      },
      branches: <StatefulShellBranch>[
        // Tab Admin 1: Home
        StatefulShellBranch(
          navigatorKey: _navigatorHomeAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/homeAdmin',
              name: Routes().homeAdmin,
              builder: (context, state) {
                return const HomePage();
              },
            ),
          ],
        ),
        // Tab Admin 2: Building Management (CRUD Gedung & Eskul)
        StatefulShellBranch(
          navigatorKey: _navigatorBuildingAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/buildingAdmin',
              name: Routes().buildingAdmin,
              builder: (context, state) {
                return const BuildingPage();
              },
              routes: [
                // Sub-route: Tambah Gedung
                GoRoute(
                  path: 'createBuilding',
                  name: Routes().createBuilding,
                  builder: (context, state) {
                    return const AddBuildingPage();
                  },
                  // Refresh list gedung saat kembali dari halaman tambah
                  onExit: (context, state) {
                    BlocProvider.of<BuildingBloc>(context)
                        .add(GetBuildingByAgency());
                    return true;
                  },
                  routes: [
                    // Nested Sub-route: Edit Gedung
                    GoRoute(
                      path: 'editBuilding',
                      name: Routes().editBuilding,
                      builder: (context, state) {
                        return EditBuildingPage(
                          building: state.extra as BuildingModel,
                        );
                      },
                      // Refresh list gedung saat kembali dari halaman edit
                      onExit: (context, state) {
                        BlocProvider.of<BuildingBloc>(context)
                            .add(GetBuildingByAgency());
                        return true;
                      },
                    ),
                  ],
                ),
                // Sub-route: Tambah Ekstrakurikuler
                GoRoute(
                  path: 'createExtracurricular',
                  name: Routes().createExtracurricular,
                  builder: (context, state) {
                    return const AddExtracurricularPage();
                  },
                  onExit: (context, state) {
                    BlocProvider.of<ExtracurricularBloc>(context)
                        .add(GetExtracurricular());
                    return true;
                  },
                  routes: [
                    // Nested Sub-route: Edit Ekstrakurikuler
                    GoRoute(
                      path: 'editExtracurricular',
                      name: Routes().editExtracurricular,
                      builder: (context, state) {
                        return EditExtracurricularPage(
                          excur: state.extra as ExtracurricularModel,
                        );
                      },
                      onExit: (context, state) {
                        BlocProvider.of<ExtracurricularBloc>(context)
                            .add(GetExtracurricular());
                        return true;
                      },
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
        // Tab Admin 3: Report (Laporan/Riwayat)
        StatefulShellBranch(
          navigatorKey: _navigatorReportAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/reportAdmin',
              name: Routes().reportAdmin,
              builder: (context, state) {
                return const HistoryPage();
              },
            ),
          ],
        ),
        // Tab Admin 4: Profile & User Management
        StatefulShellBranch(
          navigatorKey: _navigatorProfileAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/profileAdmin',
              name: Routes().profileAdmin,
              builder: (context, state) {
                return const ProfilePage();
              },
              routes: [
                GoRoute(
                  path: 'addUser',
                  name: Routes().addUser,
                  builder: (context, state) {
                    return AddUserPage(
                      userModel: state.extra as UserModel,
                    );
                  },
                ),
                GoRoute(
                  path: 'editUser',
                  name: Routes().editUser,
                  builder: (context, state) {
                    return EditUserPage(
                      userModel: state.extra as UserModel,
                    );
                  },
                  onExit: (context, state) {
                    // Refresh data user admin saat selesai edit
                    BlocProvider.of<RegisterBloc>(context)
                        .add(GetAllUserAdmin());
                    return true;
                  },
                ),
                GoRoute(
                  path: 'detailUser',
                  name: Routes().detailUser,
                  builder: (context, state) {
                    return DetailProfilePage(
                      userModel: state.extra as UserModel,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    /// 3. Navigation Bottom Bar untuk SUPER ADMIN
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BotNavBar(
          navigationShell: navigationShell,
        );
      },
      branches: <StatefulShellBranch>[
        // Tab Super Admin 1: Home (Management User)
        StatefulShellBranch(
          navigatorKey: _navigatorHomeSuperAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/homeSuperAdmin',
              name: Routes().homeSuperAdmin,
              builder: (context, state) {
                return const HomePage();
              },
              routes: [
                GoRoute(
                  path: 'addUserSuperAdmin',
                  name: Routes().addUserSuperAdmin,
                  builder: (context, state) {
                    return AddUserPage(
                      userModel: state.extra as UserModel,
                    );
                  },
                ),
                GoRoute(
                  path: 'editUserSuperAdmin',
                  name: Routes().editUserSuperAdmin,
                  builder: (context, state) {
                    return EditUserPage(
                      userModel: state.extra as UserModel,
                    );
                  },
                  onExit: (context, state) {
                    // Refresh list semua user saat kembali
                    BlocProvider.of<RegisterBloc>(context)
                        .add(GetAllUserSuperAdmin());
                    return true;
                  },
                ),
                GoRoute(
                  path: 'detailUserSuperAdmin',
                  name: Routes().detailUserSuperAdmin,
                  builder: (context, state) {
                    return DetailProfilePage(
                      userModel: state.extra as UserModel,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Tab Super Admin 2: Profile
        StatefulShellBranch(
          navigatorKey: _navigatorProfileSuperAdmin,
          routes: <RouteBase>[
            GoRoute(
              path: '/profileSuperAdmin',
              name: Routes().profileSuperAdmin,
              builder: (context, state) {
                return const ProfilePage();
              },
            ),
          ],
        ),
      ],
    ),
  ],
);