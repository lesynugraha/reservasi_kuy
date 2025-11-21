import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/model/reservation_model.dart';
import '../../utils/constant/constant.dart';
import '../../utils/general/parsing.dart';
import '../../widgets/general/widget_title_desc_card_view.dart';
import '../../widgets/general/widget_text_content_reservation.dart';
import '../../widgets/general/dialog_proof_view.dart';
import '../../utils/routes/route_name.dart'; // Import Routes
import 'widget_button_action.dart';

class ReservationCardView extends StatelessWidget {
  const ReservationCardView({
    super.key,
    required this.reservation,
    this.acceptFunction,
    this.declineFunction,
    this.doneFunction,
    this.cancelFunction,
    this.deleteFunction,
    required this.role,
  });

  final ReservationModel reservation;
  final VoidCallback? acceptFunction;
  final VoidCallback? declineFunction;
  final VoidCallback? doneFunction;
  final VoidCallback? cancelFunction;
  final VoidCallback? deleteFunction;
  final String role;

  imageLoader() {
    if (reservation.image == "") {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const Image(
              height: 100,
              width: 100,
              fit: BoxFit.cover,
              image: AssetImage(assetsDefaultBuildingImage),
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              height: 100,
              width: 100,
              imageUrl: reservation.image!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorWidget: (context, url, error) {
                return const Image(
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  image: AssetImage(assetsDefaultBuildingImage),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageLoader(),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextTitleDescriptionCardView(
                          text: reservation.buildingName!,
                          isTitle: true,
                        ),
                        role == "1"
                            ? TextContentCardView(
                          name: "Pengguna",
                          content: reservation.contactName!,
                        )
                            : const SizedBox(),
                        TextContentCardView(
                          name: "Mulai",
                          content: ParsingString()
                              .convertDateWithHour(reservation.dateStart!),
                        ),
                        TextContentCardView(
                          name: "Selesai",
                          content: ParsingString()
                              .convertDateWithHour(reservation.dateEnd!),
                        ),
                        TextContentCardView(
                          name: "Status",
                          content: reservation.status!,
                        ),
                        const TextTitleDescriptionCardView(
                          text: "Keterangan",
                        ),
                        TextTitleDescriptionCardView(
                          text: reservation.information!,
                        ),
                        // Menampilkan tombol Bukti jika ada
                        if (reservation.proofImage != null &&
                            reservation.proofImage!.isNotEmpty) ...[
                          const Gap(8),
                          InkWell(
                            onTap: () {
                              DialogProofView.show(
                                  context, reservation.proofImage!);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility,
                                      size: 16, color: Colors.blue),
                                  Gap(5),
                                  Text(
                                    "Lihat Bukti Pengajuan",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Gap(10),
                      ],
                    ),
                  ),
                ],
              ),
              // Pass context ke buttonByRole
              buttonByRole(context),
            ],
          ),
        ),
      ),
    );
  }

  buttonByRole(BuildContext context) {
    if (role == "1") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ButtonAction(
            name: "Tolak",
            function: declineFunction ?? () {},
          ),
          const Gap(10),
          ButtonAction(
            name: "Terima",
            function: acceptFunction ?? () {},
          ),
        ],
      );
    } else if (role == "2") {
      return Align(
        alignment: Alignment.bottomRight,
        child: Builder(
          builder: (ctx) {
            if (reservation.status == "Menunggu") {
              return ButtonAction(
                name: "Batal",
                function: cancelFunction ?? () {},
              );
            } else if (reservation.status == "Disetujui") {
              return ButtonAction(
                name: "Selesai",
                function: doneFunction ?? () {},
              );
            } else if (reservation.status == "Ditolak") {
              // REVISI TOMBOL DAN NAVIGASI
              return ButtonAction(
                name: "Reservasi telah tervalidasi",
                function: () {
                  if (deleteFunction != null) {
                    deleteFunction!();
                  }
                  // Navigasi ke History setelah tombol ditekan
                  Navigator.pushNamed(context, Routes().history);
                },
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      );
    } else {
      return const SizedBox();
    }
  }
}