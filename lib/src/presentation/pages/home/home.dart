import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Model & Repositories
import '../../../data/model/reservation_model.dart';
import '../../../data/model/user_model.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/utils/notification_services.dart';

// Import Bloc
import '../../../data/bloc/history/history_bloc.dart';
import '../../../data/bloc/register/register_bloc.dart';
import '../../../data/bloc/reservation/reservation_bloc.dart';
import '../../../data/bloc/user/user_bloc.dart';

// Import Utils & Widgets
import '../../utils/general/parsing.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/header_pages.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_loading.dart';
import 'widget_reservation_card_view.dart';
import 'widget_supervisor_card_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late DateTime dateTime;
  late String date;
  late ReservationBloc reservationBloc;
  late UserBloc userBloc;
  late HistoryBloc historyBloc;
  late String userRole;
  late RegisterBloc registerBloc;

  /// user: mendapatkan informasi list reservasi
  getReservationForUser() {
    reservationBloc = context.read<ReservationBloc>();
    reservationBloc.add(GetReservationForUser());
  }

  /// user: update laporan diselesaikan
  updateReportFinished(String id) {
    historyBloc = context.read<HistoryBloc>();
    historyBloc.add(UpdateFinishedReport(id));
  }

  /// user: membuat riwayat
  createHistory(ReservationModel reservation, String status) {
    historyBloc = context.read<HistoryBloc>();
    historyBloc.add(
      CreateHistory(
        reservation.buildingName!,
        reservation.dateStart!,
        reservation.dateEnd!,
        reservation.dateCreated!,
        reservation.contactId!,
        reservation.contactName!,
        reservation.information!,
        status,
        reservation.image!,
        note: reservation.note,
        proofImage: reservation.proofImage,
      ),
    );
  }

  /// user: menghapus reservasi dan membuat history
  // Mengembalikan fungsi (closure) agar bisa dipanggil kapan saja
  actionReservationUser(ReservationModel reservation, String status) {
    return () {
      reservationBloc = context.read<ReservationBloc>();
      reservationBloc.add(DeleteReservation(reservation.id!));
      createHistory(reservation, status);
      updateReportFinished(reservation.id!);
    };
  }

  /// admin: membuat laporan custom id
  createReportCustomId(ReservationModel reservation, String status, String id,
      {String? note}) {
    historyBloc = context.read<HistoryBloc>();
    historyBloc.add(
      CreateReportCustomId(
        id,
        reservation.buildingName!,
        reservation.dateStart!,
        reservation.dateEnd!,
        reservation.dateCreated!,
        reservation.contactId!,
        reservation.contactName!,
        reservation.information!,
        status,
        reservation.image!,
        note: note,
        proofImage: reservation.proofImage,
      ),
    );
  }

  /// admin: membuat laporan
  createReport(ReservationModel reservation, String status) {
    historyBloc = context.read<HistoryBloc>();
    historyBloc.add(
      CreateReport(
        reservation.buildingName!,
        reservation.dateStart!,
        reservation.dateEnd!,
        reservation.dateCreated!,
        reservation.contactId!,
        reservation.contactName!,
        reservation.information!,
        status,
        reservation.image!,
      ),
    );
  }

  /// admin: informasi list reservasi
  getReservationForAdmin() {
    reservationBloc = context.read<ReservationBloc>();
    reservationBloc.add(GetReservationForAdmin());
  }

  /// admin: menerima dan menolak reservasi serta membuat laporan
  actionReservationAdmin(ReservationModel reservation, String status,
      {String? note}) {
    reservationBloc = context.read<ReservationBloc>();
    reservationBloc.add(
        UpdateStatusReservation(reservation.id!, status, note: note));

    createReportCustomId(reservation, status, reservation.id!, note: note);
  }

  /// super admin: delete akun supervisor
  deleteUserSupervisor(String agency) {
    return () {
      registerBloc = context.read<RegisterBloc>();
      registerBloc.add(DeleteUserSuperAdmin(agency));
    };
  }

  /// super admin: fungsi untuk mendapatkan info list user
  getAllUserSuperAdmin() {
    registerBloc = context.read<RegisterBloc>();
    registerBloc.add(GetAllUserSuperAdmin());
  }

  /// umum: informasi pengguna yang login
  getUser() {
    userBloc = context.read<UserBloc>();
    userBloc.add(GetUserLoggedIn());
  }

  /// umum: informasi waktu saat ini
  getDateTime() {
    dateTime = DateTime.now();
    date = dateTime.toString();
  }

  // Fungsi Update Token Otomatis
  _updateFCMToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString("user");

      if (username != null) {
        String? token = await NotificationServices().getDeviceToken();
        if (token != null) {
          await UserRepo().updateUserFCMToken(username, token);
          if (kDebugMode) {
            print("✅ Token diperbarui otomatis di Home untuk: $username");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error auto-update token: $e");
      }
    }
  }

  /// umum: informasi role
  getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("role")) {
      userRole = prefs.getString("role")!;
      setState(() {
        userRole = userRole;
      });
    } else {
      setState(() {
        userRole = "";
      });
    }
  }

  @override
  void didChangeDependencies() {
    userRole = "";
    getRole();
    getDateTime();
    getUser();
    getAllUserSuperAdmin();
    _updateFCMToken();

    super.didChangeDependencies();
  }

  /// umum: fungsi reservasi berdasarkan role
  getReservationByRole() {
    if (userRole == "0") {
      return getAllUserSuperAdmin();
    } else if (userRole == "1") {
      return getReservationForAdmin();
    } else if (userRole == "2") {
      return getReservationForUser();
    } else {}
  }

  /// umum: informasi home berdasarkan role
  contentHomeByRole() {
    if (userRole == "0") {
      return superAdminContent();
    } else if (userRole == "1") {
      return adminContent();
    } else if (userRole == "2") {
      return userContent();
    } else {
      return const SizedBox();
    }
  }

  Container isEmptyText(String text) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            text,
            maxLines: 3,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Container superAdminContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueAccent,
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Akun Supervisor",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: Colors.white,
            ),
            const Gap(10),
            BlocBuilder<RegisterBloc, RegisterState>(
              builder: (context, state) {
                if (state is GetAllUserSuccess) {
                  final user = state.listUser;
                  user.sort((a, b) => a.fullName!.compareTo(b.fullName!));
                  return Column(
                    children: [
                      user.isNotEmpty
                          ? ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: user.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return SupervisorCardView(
                            user: user[index],
                            editFunction: () {
                              context.pushNamed(
                                Routes().editUserSuperAdmin,
                                extra: user[index],
                              );
                            },
                            deleteFunction: () {
                              PopUp().whenDoSomething(
                                context,
                                "Yakin ingin menghapus instansi ${user[index].agency!}",
                                Icons.delete_forever,
                                deleteUserSupervisor(user[index].agency!),
                              );
                            },
                            detailFunction: () {
                              context.pushNamed(
                                Routes().detailUserSuperAdmin,
                                extra: user[index],
                              );
                            },
                          );
                        },
                      )
                          : isEmptyText("Tidak ada akun supervisor"),
                      const Gap(30),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                context.pushNamed(Routes().addUserSuperAdmin,
                                    extra: UserModel(role: userRole));
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 12,
                                ),
                                child: Text(
                                  "Tambah Akun Supervisor",
                                  style: GoogleFonts.openSans(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Container adminContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueAccent,
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Konfirmasi Reservasi",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: Colors.white,
            ),
            const Gap(10),
            BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, state) {
                if (state is ReservationGetSuccess) {
                  final reservations = state.reservations
                      .where((element) => element.status == "Menunggu")
                      .toList();
                  reservations.sort(
                        (a, b) => a.dateCreated!.compareTo(b.dateCreated!),
                  );
                  if (reservations.isNotEmpty) {
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: reservations.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ReservationCardView(
                          reservation: reservations[index],
                          acceptFunction: () {
                            PopUp().whenDoSomething(
                              context,
                              "Setujui Reservasi?",
                              Icons.check,
                                  () {
                                actionReservationAdmin(
                                    reservations[index], "Disetujui");
                              },
                            );
                          },
                          declineFunction: () {
                            PopUp().whenDoSomethingWithInput(
                              context,
                              "Tolak Reservasi?",
                              "Alasan Penolakan",
                              Icons.cancel,
                                  (alasan) {
                                actionReservationAdmin(
                                  reservations[index],
                                  "Ditolak",
                                  note: alasan,
                                );
                              },
                            );
                          },
                          role: userRole,
                        );
                      },
                    );
                  } else {
                    return isEmptyText("Tidak ada reservasi yang menunggu");
                  }
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Container userContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.blueAccent,
      ),
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Reservasi Anda",
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: Colors.white,
            ),
            const Gap(10),
            BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, state) {
                if (state is ReservationGetSuccess) {
                  final reservations = state.reservations;
                  reservations.sort(
                        (a, b) => b.dateCreated!.compareTo(a.dateCreated!),
                  );
                  if (reservations.isNotEmpty) {
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: reservations.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        return ReservationCardView(
                          reservation: reservations[index],
                          doneFunction: () {
                            PopUp().whenDoSomething(
                              context,
                              "Ingin menyelesaikan reservasi?",
                              Icons.check_circle,
                              actionReservationUser(
                                reservations[index],
                                "Selesai",
                              ),
                            );
                          },
                          cancelFunction: () {
                            PopUp().whenDoSomething(
                              context,
                              "Ingin membatalkan reservasi?",
                              Icons.cancel,
                              actionReservationUser(
                                reservations[index],
                                "Dibatalkan",
                              ),
                            );
                          },
                          // vvv PERBAIKAN UTAMA DISINI vvv
                          // Kita membungkus logika hapus dan logika navigasi bersama-sama
                          deleteFunction: () {
                            // 1. Jalankan fungsi hapus (actionReservationUser mengembalikan function)
                            actionReservationUser(
                                reservations[index], "Ditolak")();

                            // 2. Paksa pindah ke halaman History menggunakan GoRouter
                            // Ini menjamin navigasi berjalan setelah tombol ditekan
                            context.goNamed(Routes().history);
                          },
                          // ^^^ SELESAI PERBAIKAN ^^^
                          role: userRole,
                        );
                      },
                    );
                  } else {
                    return isEmptyText(
                        "Anda saat ini belum melakukan reservasi");
                  }
                } else {
                  return const SizedBox();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    getReservationByRole();
    return Scaffold(
      body: Stack(
        children: [
          MultiBlocListener(
            listeners: [
              BlocListener<ReservationBloc, ReservationState>(
                listener: (context, state) {
                  if (state is ReservationUpdateSuccess) {
                    PopUp().whenSuccessDoSomething(
                      context,
                      "Berhasil",
                      Icons.check_circle,
                    );
                  }
                  // Popup "Berhasil Hapus" SUDAH DIHAPUS agar tidak mengganggu navigasi
                },
              ),
              BlocListener<RegisterBloc, RegisterState>(
                listener: (context, state) {
                  if (state is DeleteSuccess) {
                    PopUp().whenSuccessDoSomething(
                      context,
                      "Berhasil",
                      Icons.check_circle,
                    );
                  }
                },
              ),
            ],
            child: Scaffold(
              body: Column(
                children: [
                  const HeaderPage(name: "Beranda"),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        getReservationByRole();
                        getDateTime();
                        getUser();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Gap(10),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        ParsingString().convertDate(date),
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  BlocBuilder<UserBloc, UserState>(
                                    builder: (context, state) {
                                      if (state is UserGetSuccess) {
                                        return Text(
                                          "${state.user.fullName}",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                        );
                                      } else {
                                        return const Text(
                                          "Pengguna",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const Gap(20),
                              contentHomeByRole(),
                              const Gap(40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: BlocBuilder<HistoryBloc, HistoryState>(
              builder: (context, state) {
                if (state is HistoryLoading) {
                  return const CustomLoading();
                }
                return const SizedBox();
              },
            ),
          ),
          Center(
            child: BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, state) {
                if (state is ReservationLoading) {
                  return const CustomLoading();
                }
                return const SizedBox();
              },
            ),
          ),
          Center(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const CustomLoading();
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}