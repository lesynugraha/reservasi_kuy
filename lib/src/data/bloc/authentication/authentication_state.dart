part of 'authentication_bloc.dart';

// AuthenticationState adalah base class (blueprint) untuk semua kondisi yang mungkin terjadi
// dalam proses login.
// Kita menggunakan library 'Equatable' agar BLoC bisa membandingkan state lama dan state baru.
// Jika state dianggap sama (props-nya sama), UI tidak akan di-rebuild (ini untuk performa).
abstract class AuthenticationState extends Equatable {
  const AuthenticationState();
}

// State awal saat layar pertama kali dibuka, belum ada aksi apa-apa.
class LoginInitial extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// State saat tombol login ditekan dan aplikasi sedang menunggu respon dari server.
// UI akan merespon state ini dengan menampilkan CircularProgressIndicator (Loading).
class LoginLoading extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// State jika login berhasil secara umum (kadang dipakai sebelum cek role).
class LoginSuccess extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// State jika login gagal (password salah, email tidak ada, atau tidak ada internet).
// Class ini membawa data 'error' (String) yang nanti akan ditampilkan di SnackBar/Alert.
class LoginFailed extends AuthenticationState {
  final String error;

  const LoginFailed(this.error);

  // Props berisi [error], jadi jika error message-nya beda, dianggap state baru -> UI update.
  @override
  List<Object> get props => [error];
}

// State umum jika user terautentikasi (bisa jadi parent state).
class IsAuthenticated extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// ============================================================================
// STATE KHUSUS ROLE (PENTING UNTUK NAVIGASI)
// ============================================================================
// Ketiga state di bawah ini menentukan user akan dibawa ke halaman mana.
// Logikanya ada di UI (misal: main.dart atau login.dart):
// "If state is IsAdmin -> Go to AdminHomePage"
// "If state is IsUser -> Go to UserHomePage"

// Jika yang login adalah Admin Sekolah (Supervisor) - Role "1"
class IsAdmin extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// Jika yang login adalah User Biasa (Siswa/Anggota Ekskul) - Role "2"
class IsUser extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// Jika yang login adalah Super Admin (IT Support/Pengelola Sistem) - Role "0"
class IsSuperAdmin extends AuthenticationState {
  @override
  List<Object> get props => [];
}

// State jika tidak ada user yang login (misal setelah logout atau token expired).
// UI akan melempar user kembali ke halaman Login.
class UnAuthenticated extends AuthenticationState {
  @override
  List<Object> get props => [];
}