import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/bloc/logout/logout_bloc.dart';
import '../../../data/bloc/register/register_bloc.dart';
import '../../../data/bloc/user/user_bloc.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/image_picker.dart';
import '../../utils/routes/route_name.dart';
import '../../widgets/general/custom_fab.dart';
import '../../widgets/general/header_pages.dart';
import '../../widgets/general/pop_up.dart';
import '../../widgets/general/widget_custom_loading.dart';
import 'widget_profile_text_field.dart';
import '../../widgets/general/widget_custom_title_text_form_field.dart';
import 'widget_user_card_view.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// Menggunakan TickerProviderStateMixin untuk animasi TabBar.
class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {

  // Bloc untuk berbagai fitur di halaman profil
  late LogoutBloc logoutBloc;
  late RegisterBloc registerBloc;
  late UserBloc userBloc;

  // Controller untuk field data profil
  late TextEditingController idController;
  late TextEditingController agencyController;
  late TextEditingController usernameController;
  late TextEditingController fullNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController imageController;

  // Controller sementara untuk edit field (seperti nama/email) via popup
  late TextEditingController temporaryController;

  late String roleUser;
  late TabController tabController;
  int selectedIndex = 0; // Index tab yang aktif (0: Admin, 1: User)

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? imagePicked;

  /// Fetch semua user untuk Admin Sekolah (Supervisor).
  /// Hanya mengambil user (siswa) yang terdaftar di sekolah tersebut.
  getAllUserAdmin() {
    registerBloc = context.read<RegisterBloc>();
    registerBloc.add(GetAllUserAdmin());
  }

  /// Fetch semua user untuk Super Admin.
  /// Mengambil daftar Supervisor Sekolah.
  getAllUserSuperAdmin() {
    registerBloc = context.read<RegisterBloc>();
    registerBloc.add(GetAllUserSuperAdmin());
  }

  /// Fetch data diri user yang sedang login.
  getSingleUser() {
    userBloc = context.read<UserBloc>();
    userBloc.add(GetUserLoggedIn());
  }

  /// Update data profil user yang sedang login.
  editSingleUser() {
    userBloc = context.read<UserBloc>();
    userBloc.add(
      EditSingleUser(
        idController.text,
        agencyController.text,
        usernameController.text,
        passwordController.text,
        fullNameController.text,
        emailController.text,
        phoneController.text,
      ),
    );
  }

  /// Hapus user lain (Fitur Admin).
  deleteUser(String id) {
    return () {
      registerBloc = context.read<RegisterBloc>();
      registerBloc.add(DeleteUser(id));
    };
  }

  /// Cek role user dari SharedPreferences.
  getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roleUser = prefs.getString("role")!;
    setState(() {
      roleUser = roleUser;
    });
  }

  /// Fungsi Logout.
  /// Menghapus sesi login dan token FCM di backend jika perlu.
  logout() {
    return () {
      logoutBloc = context.read<LogoutBloc>();
      logoutBloc.add(OnLogout());
    };
  }

  /// Fitur Ganti Foto Profil:
  /// 1. Pilih gambar dari galeri.
  /// 2. Upload ke Firebase Storage dengan nama file unik (username + timestamp).
  /// 3. Update URL foto profil di database user.
  selectImage() async {
    Uint8List img = await StoreData().pickImage(ImageSource.gallery);
    final urlImage = await StoreData().uploadImageToStorage(
        "profile_picture",
        "${usernameController.text}${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}",
        img);
    setState(() {
      imagePicked = img;
    });
    uploadImage(urlImage);
  }

  /// Trigger event update URL foto profil ke Bloc.
  uploadImage(String urlImage) {
    userBloc = context.read<UserBloc>();
    userBloc.add(
      EditProfilePicture(
        idController.text,
        urlImage,
      ),
    );
  }

  /// Helper untuk menentukan fetch data user berdasarkan role admin.
  getALlUserByRole() {
    if (roleUser == "0") {
      return getAllUserSuperAdmin();
    } else if (roleUser == "1") {
      return getAllUserAdmin();
    } else {
      return () {};
    }
  }

  @override
  void didChangeDependencies() {
    // Inisialisasi awal.
    roleUser = "";
    getRole();
    getSingleUser(); // Load data profil sendiri

    tabController = TabController(
      length: 2,
      vsync: this,
    );
    // Inisialisasi semua controller text field
    idController = TextEditingController();
    agencyController = TextEditingController();
    usernameController = TextEditingController();
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    imageController = TextEditingController();
    temporaryController = TextEditingController();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Bersihkan semua controller dan listener
    idController.dispose();
    agencyController.dispose();
    usernameController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    imageController.dispose();
    tabController.dispose();
    temporaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener Logout: Pindah ke halaman Login jika sukses keluar.
        BlocListener<LogoutBloc, LogoutState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              context.goNamed(Routes().login);
            }
          },
        ),
        // Listener Data User: Mengisi text controller saat data berhasil diambil dari backend.
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserGetSuccess) {
              final user = state.user;
              idController = TextEditingController(text: user.id);
              agencyController = TextEditingController(text: user.agency);
              usernameController = TextEditingController(text: user.username);
              fullNameController = TextEditingController(text: user.fullName);
              emailController = TextEditingController(text: user.email);
              phoneController = TextEditingController(text: user.phone);
              passwordController = TextEditingController(text: user.password);
              imageController = TextEditingController(text: user.image);
            }

          },
        ),
        // Listener Register (Hapus User): Notifikasi sukses hapus.
        BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is DeleteSuccess) {
              PopUp().whenSuccessDoSomething(
                context,
                "User berhasil dihapus",
                Icons.check_circle,
              );
            }
          },
        )
      ],
      child: Scaffold(
        // Floating Action Button (FAB) hanya muncul di tab "User" (index 1) untuk Admin menambah user baru.
        floatingActionButton: selectedIndex == 1
            ? BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserGetSuccess) {
              return CustomFAB(
                iconData: Icons.person_add,
                function: () {
                  context.pushNamed(
                    Routes().addUser,
                    extra: state.user,
                  );
                },
              );
            } else {
              return const SizedBox();
            }
          },
        )
            : null,
        body: Stack(
          children: [
            Column(
              children: [
                const HeaderPage(
                  name: "Profil Saya",
                ),
                const Gap(10),
                // Konten dinamis berdasarkan role (Admin lihat TabBar, User lihat Profil saja).
                Expanded(
                  child: contentByRole(),
                ),
              ],
            ),
            // Loading Overlay untuk berbagai Bloc
            Center(
              child: BlocBuilder<LogoutBloc, LogoutState>(
                builder: (context, state) {
                  if (state is LogoutLoading) {
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
            Center(
              child: BlocBuilder<RegisterBloc, RegisterState>(
                builder: (context, state) {
                  if (state is RegisterLoading) {
                    return const CustomLoading();
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

  // Logika Tampilan:
  // Role 1 (Supervisor/Admin) -> Tampilan Admin (TabBar Manajemen).
  // Role 2 (User Biasa) -> Tampilan User (Hanya Profil Diri).
  contentByRole() {
    if (roleUser == "1") {
      return adminUI();
    } else {
      return userContent();
    }
  }

  // Helper tampilan foto profil.
  // Prioritas: Gambar baru dipilih (imagePicked) > Gambar dari URL (imageController) > Gambar Default.
  imageLoader() {
    if (imagePicked != null) {
      return ClipOval(
        child: Image(
          height: 150,
          width: 150,
          image: MemoryImage(imagePicked!),
          fit: BoxFit.cover,
        ),
      );
    } else {
      if (imageController.text == "") {
        return ClipOval(
          child: Image.asset(
            assetsDefaultProfilePicture,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return ClipOval(
          child: CachedNetworkImage(
            height: 150,
            width: 150,
            imageUrl: imageController.text,
            fit: BoxFit.cover,
            placeholder: (context, url) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
            errorWidget: (context, url, error) {
              return Image.asset(
                assetsDefaultProfilePicture,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              );
            },
          ),
        );
      }
    }
  }

  // Tampilan UI untuk Admin: TabBar "Admin" (Profil Diri) dan "User" (Manajemen Siswa).
  Column adminUI() {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          labelStyle: GoogleFonts.openSans(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelColor: Colors.black,
          labelColor: Colors.white,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          tabs: [
            Tab(
              child: Container(
                width: double.maxFinite,
                height: 40,
                decoration: selectedIndex == 0
                    ? BoxDecoration(
                  color: Colors.blueAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                )
                    : BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text("Admin"),
                ),
              ),
            ),
            Tab(
              child: Container(
                width: double.maxFinite,
                height: 40,
                decoration: selectedIndex == 1
                    ? BoxDecoration(
                  color: Colors.blueAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                )
                    : BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text("User"),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: tabController,
            children: [
              /// Tab 1: Profil Admin Sendiri (Reuse komponen userContent)
              userContent(),

              /// Tab 2: List Manajemen User (Siswa)
              adminContent(),
            ],
          ),
        ),
      ],
    );
  }

  // Konten Profil Diri (Digunakan oleh User & Admin di tab pertama).
  RefreshIndicator userContent() {
    return RefreshIndicator(
      onRefresh: () async {
        getSingleUser(); // Reload data profil
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserGetSuccess) {
              return Column(
                children: [
                  const Gap(30),
                  // Foto Profil dengan fitur ganti foto (tap ikon kamera) dan zoom (tap foto).
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke tampilan foto layar penuh (Hero animation).
                          context.pushNamed(
                            Routes().profilePictureFullScreen,
                            extra: state.user,
                          );
                        },
                        child: Hero(
                          tag: "profilePicture",
                          child: imageLoader(),
                        ),
                      ),
                      // Tombol Ganti Foto
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              width: 0.5,
                              color: Colors.white,
                            ),
                            color: Colors.grey.shade300,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                selectImage();
                              },
                              customBorder: const CircleBorder(),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                  const Gap(20),
                  // Form Data Profil
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomTitleTextFormField(subtitle: "Nama Pengguna"),
                        CustomProfileTextFormField(
                          fieldName: "Username",
                          controller: usernameController,
                          prefixIcon: Icons.person,
                        ),
                        const CustomTitleTextFormField(subtitle: "Instansi"),
                        CustomProfileTextFormField(
                          fieldName: "Instansi",
                          controller: agencyController,
                          prefixIcon: Icons.corporate_fare,
                        ),
                        // Field yang bisa diedit (Nama, Email, Telepon) menggunakan Popup Edit.
                        const CustomTitleTextFormField(
                            subtitle: "Nama Lengkap"),
                        CustomProfileTextFormField(
                          fieldName: "Nama Lengkap",
                          controller: fullNameController,
                          prefixIcon: Icons.contact_mail,
                          function: () {
                            PopUp().whenEditField(
                              context,
                              _formKey,
                              "Nama Lengkap",
                              fullNameController,
                              temporaryController,
                              Icons.person,
                                  () {
                                return editSingleUser();
                              },
                            );
                          },
                          isEdit: true,
                        ),
                        const CustomTitleTextFormField(subtitle: "E-Mail"),
                        CustomProfileTextFormField(
                          fieldName: "E-Mail",
                          controller: emailController,
                          prefixIcon: Icons.email,
                          function: () {
                            PopUp().whenEditField(
                              context,
                              _formKey,
                              "E-Mail",
                              emailController,
                              temporaryController,
                              Icons.email,
                                  () {
                                return editSingleUser();
                              },
                            );
                          },
                          isEdit: true,
                        ),
                        const CustomTitleTextFormField(
                            subtitle: "Nomor Telepon"),
                        CustomProfileTextFormField(
                          fieldName: "Nomor Telepon",
                          controller: phoneController,
                          prefixIcon: Icons.phone_android,
                          function: () {
                            PopUp().whenEditField(
                              context,
                              _formKey,
                              "Nomor Telepon",
                              phoneController,
                              temporaryController,
                              Icons.email,
                                  () {
                                return editSingleUser();
                              },
                            );
                          },
                          isEdit: true,
                        ),
                        // Field Password khusus, navigasi ke halaman ganti password.
                        const CustomTitleTextFormField(subtitle: "Kata Sandi"),
                        CustomProfileTextFormField(
                          fieldName: "Password",
                          controller: passwordController,
                          prefixIcon: Icons.lock,
                          function: () {
                            context.pushNamed(
                              Routes().editPassword,
                              extra: state.user,
                            );
                          },
                          isEdit: true,
                        ),
                        const Gap(30),
                      ],
                    ),
                  ),
                  // Tombol Keluar (Logout)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: Colors.blueAccent,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            PopUp().whenDoSomething(
                              context,
                              "Yakin ingin keluar?",
                              Icons.logout,
                              logout(),
                            );
                          },
                          borderRadius: BorderRadius.circular(15),
                          splashColor: Colors.blue,
                          child: Center(
                              child: Text(
                                "Keluar",
                                style: GoogleFonts.openSans(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )),
                        ),
                      ),
                    ),
                  ),
                  const Gap(40),
                ],
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  // Konten Daftar User (Hanya untuk Admin).
  RefreshIndicator adminContent() {
    getALlUserByRole(); // Load data siswa
    return RefreshIndicator(
      onRefresh: () async {
        getALlUserByRole();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            if (state is GetAllUserSuccess) {
              final user = state.listUser;
              user.sort((a, b) => a.fullName!.compareTo(b.fullName!)); // Sorting A-Z
              if (user.isNotEmpty) {
                return Column(
                  children: [
                    const Gap(10),
                    Text(
                      "Daftar User",
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // List User Card dengan opsi Edit, Hapus, dan Detail.
                    ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 80,
                        top: 10,
                      ),
                      itemCount: user.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: UserCardView(
                            user: user[index],
                            editFunction: () {
                              // Routing edit berbeda antara Admin Sekolah dan SuperAdmin
                              roleUser == "1"
                                  ? context.pushNamed(
                                Routes().editUser,
                                extra: user[index],
                              )
                                  : context.pushNamed(
                                Routes().editUserSuperAdmin,
                                extra: user[index],
                              );
                            },
                            deleteFunction: () {
                              PopUp().whenDoSomething(
                                context,
                                "Yakin ingin menghapus ${user[index].fullName!}",
                                Icons.delete_forever,
                                deleteUser(user[index].id!),
                              );
                            },
                            detailFunction: () {
                              context.pushNamed(
                                Routes().detailUser,
                                extra: user[index],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    const Gap(30),
                    Center(
                      child: Text(
                        "Data user kosong",
                        style: GoogleFonts.openSans(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }
}