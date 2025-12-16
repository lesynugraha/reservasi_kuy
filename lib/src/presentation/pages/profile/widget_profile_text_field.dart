import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Widget Form Field Kustom yang dikhususkan untuk halaman Profil.
// Menggabungkan logika tampilan (UI) dan logika validasi input menjadi satu komponen reusable.
class CustomProfileTextFormField extends StatefulWidget {
  const CustomProfileTextFormField({
    super.key,
    required this.fieldName, // Label field (Contoh: "Email", "Password")
    required this.controller,
    required this.prefixIcon,
    this.function,   // Callback fungsi saat tombol suffix ditekan (misal: tombol edit)
    this.isEdit,     // Flag apakah field ini dalam mode bisa diedit
    this.canVisible, // Flag khusus untuk password (fitur show/hide text)
  });

  final String fieldName;
  final TextEditingController controller;
  final IconData prefixIcon;
  final VoidCallback? function;
  final bool? isEdit;
  final bool? canVisible;

  @override
  State<CustomProfileTextFormField> createState() =>
      _CustomProfileTextFormFieldState();
}

class _CustomProfileTextFormFieldState
    extends State<CustomProfileTextFormField> {
  // State lokal untuk mengatur visibilitas password (tersembunyi/terlihat)
  bool obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 6,
        bottom: 12,
      ),
      child: TextFormField(
        controller: widget.controller,
        // Helper _obscureText menentukan apakah teks harus disensor (bintang-bintang) atau tidak
        obscureText: _obscureText(widget.fieldName, obscureText),
        // Field di profil default-nya ReadOnly agar tidak teredit sembarangan,
        // kecuali dipicu oleh tombol edit (suffix icon).
        readOnly: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        // Keyboard type menyesuaikan jenis input (email, nomor, text biasa)
        keyboardType: _keyboardType(widget.fieldName),
        // Input formatter membatasi karakter apa saja yang BOLEH diketik user
        inputFormatters: _textInputFormatter(widget.fieldName),
        // Validator kustom untuk mengecek kebenaran format data (Regex)
        validator: _customValidator(widget.fieldName),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: Icon(widget.prefixIcon),
          // Suffix Icon dinamis: Bisa berupa tombol Edit, tombol Mata (visibility), atau kosong.
          suffixIcon: _suffixIcon(
            widget.fieldName,
            widget.function ?? () {},
            widget.isEdit ?? false,
            widget.canVisible ?? false,
          ),
          hintStyle: GoogleFonts.openSans(),
          hintText: widget.fieldName,
        ),
      ),
    );
  }

  // Menentukan jenis keyboard virtual yang muncul di HP User.
  TextInputType _keyboardType(String fieldName) {
    if (fieldName == "Nomor Telepon") {
      return TextInputType.phone; // Keyboard angka + simbol telepon
    } else if (fieldName == "E-Mail") {
      return TextInputType.emailAddress; // Keyboard dengan simbol '@'
    } else {
      return TextInputType.text; // Keyboard standar
    }
  }

  // Filter karakter yang diizinkan masuk ke text field.
  // Mencegah user memasukkan karakter aneh/ilegal sejak awal.
  List<TextInputFormatter> _textInputFormatter(String fieldName) {
    if (fieldName == "Username") {
      return [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // Larang spasi
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')) // Hanya huruf & angka
      ];
    } else if (fieldName == "Password") {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Password alphanumeric
      ];
    } else if (fieldName == "Nomor Telepon") {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // Hanya angka
      ];
    } else if (fieldName == "E-Mail") {
      return [
        FilteringTextInputFormatter.allow(
          RegExp(r'[a-zA-Z0-9@._-]'), // Karakter valid email
        ),
      ];
    } else if (fieldName == "Nama Lengkap") {
      return [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))]; // Huruf & spasi
    } else {
      // Default: Tidak ada batasan khusus
      return [];
    }
  }

  // Logika Validasi Form menggunakan Regex (Regular Expression).
  // Mengembalikan string error jika tidak valid, null jika valid.
  _customValidator(String fieldName) {
    if (fieldName == "Password") {
      return (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong!';
        }
        // Validasi Kompleksitas Password: Harus ada Huruf Besar DAN Angka
        if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]+$').hasMatch(value)) {
          return 'Password setidaknya mengandung huruf besar dan angka!';
        }
        if (value.length < 6) {
          return 'Password harus lebih dari 6 karakter!';
        }
        return null;
      };
    } else if (fieldName == "E-Mail") {
      return (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong!';
        }
        // Validasi Format Email Standar (harus ada @ dan .)
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Masukkan email dengan benar!';
        }
      };
    } else if (fieldName == "Nomor Telepon") {
      return (value) {
        if (value == null || value.isEmpty) {
          return 'Nomor telepon tidak boleh kosong!';
        }
        // Validasi Format No HP Indonesia: Minimal 10 digit & mulai dengan '08'
        if (value.length < 10 || !value.startsWith('08')) {
          return 'Masukkan nomor telepon dengan benar!';
        }
      };
    } else {
      // Validasi umum: Tidak boleh kosong
      return (value) {
        if (value == null || value.isEmpty) {
          return '$fieldName tidak boleh kosong!';
        } else {
          return null;
        }
      };
    }
  }

  // Mengatur ikon di sebelah kanan input field (Suffix Icon).
  _suffixIcon(
      String fieldName,
      VoidCallback function,
      bool isEdit,
      bool canVisible,
      ) {
    // Kasus 1: Password + Mode Edit -> Tombol Edit (Pindah halaman ganti password)
    if (fieldName == "Password" && isEdit == true) {
      return IconButton(
        icon: const Icon(
          Icons.edit,
        ),
        onPressed: function,
      );
    }
    // Kasus 2: Password + Fitur Show/Hide -> Tombol Mata
    else if (fieldName == "Password" && canVisible == true) {
      return IconButton(
        icon: Icon(
          obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }
    // Kasus 3: Password biasa (tanpa edit/show) -> Kosong
    else if (fieldName == "Password") {
      return const SizedBox();
    }
    // Kasus 4: Username + Mode Edit -> Tombol Edit (Popup edit username)
    else if (fieldName == "Username" && isEdit == true) {
      return IconButton(
        icon: const Icon(
          Icons.edit,
        ),
        onPressed: function,
      );
    }
    // Kasus 5: Username/Instansi biasa -> Tidak ada tombol (Read-only permanen di profil)
    else if (fieldName == "Username" || fieldName == "Instansi") {
      return null;
    }
    // Kasus 6: Field lain yang bisa diedit -> Tombol Edit
    else if (isEdit == true) {
      return IconButton(
        icon: const Icon(
          Icons.edit,
        ),
        onPressed: function,
      );
    } else {
      return null;
    }
  }

  // Helper untuk menyensor teks password.
  _obscureText(String fieldName, bool obscureText) {
    if (fieldName == "Password") {
      return obscureText;
    } else {
      return false; // Field selain password selalu terlihat
    }
  }
}