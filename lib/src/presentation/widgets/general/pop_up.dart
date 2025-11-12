import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'button_positive.dart';
import 'widget_custom_text_form_field.dart';

class PopUp {
  whenDoSomething(
      BuildContext context,
      String text,
      IconData icon,
      Function function,
      ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
                const Gap(10),
                Text(
                  text,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: Colors.blueAccent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Tidak',
                        style: GoogleFonts.openSans(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    function();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blueAccent,
                    ),
                    child: Center(
                      child: Text(
                        'Ya',
                        style: GoogleFonts.openSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  whenSuccessDoSomething(BuildContext context, String text, IconData icon,
      [bool isPop = false]) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: SizedBox(
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Icon(
                    icon,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
                const Gap(10),
                Text(
                  text,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                )
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    isPop == true ? context.pop() : null;
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blueAccent),
                    child: Center(
                      child: Text(
                        'Ya',
                        style: GoogleFonts.openSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  whenEditField(
      BuildContext context,
      GlobalKey<FormState> key,
      String fieldName,
      TextEditingController controller,
      TextEditingController tempController,
      IconData prefixIcon,
      Function function,
      ) {
    tempController.text = controller.text;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          title: Center(
            child: Text(
              "Edit $fieldName",
              style: GoogleFonts.openSans(),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: key,
              child: CustomTextFormField(
                fieldName: fieldName,
                controller: tempController,
                prefixIcon: prefixIcon,
              ),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: Colors.blueAccent,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (key.currentState!.validate()) {
                      controller.text = tempController.text;
                      function();
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    width: 100,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.blueAccent),
                    child: const Center(
                      child: Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // vvv FUNGSI BARU: Pop-up dengan Input Text vvv
  Future<void> whenDoSomethingWithInput(
      BuildContext context,
      String title,
      String labelInput,
      IconData icon,
      ValueChanged<String> function,
      ) {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 50,
                ),
                const Gap(10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(20),
                // Input Alasan
                TextFormField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: labelInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wajib diisi';
                    }
                    return null;
                  },
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.pop();
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.grey),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Batal",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    // Tombol Konfirmasi
                    Expanded(
                      // vvv SEKARANG INI AKAN BERHASIL KARENA IMPORT SUDAH ADA vvv
                      child: ButtonPositive(
                        name: "Konfirmasi",
                        function: () {
                          if (formKey.currentState!.validate()) {
                            context.pop(); // Tutup dialog
                            function(controller.text); // Panggil fungsi aksi
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}