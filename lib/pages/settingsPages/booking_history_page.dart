import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'booking_details_page.dart';

class BookingsHistoryPage extends StatefulWidget {
  const BookingsHistoryPage({super.key});

  @override
  State<BookingsHistoryPage> createState() => _BookingsHistoryPageState();
}

class _BookingsHistoryPageState extends State<BookingsHistoryPage> {
  bool loading = true;
  String? errorMessage;
  List<Map<String, dynamic>> bookings = [];
  final apiUrl = dotenv.env['API_URL'];


  @override
  void initState() {
    super.initState();
    checkAuthAndFetch();
  }

  Future<void> checkAuthAndFetch() async {
    final rawId = AuthService.userData?["id"];
    final int userId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? -1;

    await fetchBookings(userId);
  }


  Future<void> fetchBookings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${apiUrl}users/getBookingHistory/$userId"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          List<Map<String, dynamic>> rawBookings =
              List<Map<String, dynamic>>.from(data["data"]);
              print(rawBookings);

      // Format & sort bookings
      rawBookings = rawBookings.map((b) {
        DateTime? parsedDate;
        try {
          parsedDate = DateTime.parse(b["booking_date"]);
        } catch (_) {}

        return {
          ...b,
          "booking_date_fmt": parsedDate != null
              ? AppFormat.formatDateArabic(parsedDate)
              : b["booking_date"],
          "booking_start_time_fmt":
              AppFormat.formatArabicTime(b["booking_start_time"] ?? ""),
          "booking_end_time_fmt":
              AppFormat.formatArabicTime(b["booking_end_time"] ?? ""),
          "booking_status_fmt":
              AppFormat.translateStatus(b["booking_status"] ?? ""),
          "_date_sort": DateTime.parse(b["booking_creation_date"]), // for sorting
        };
      }).toList();

      // Sort: pending first, then by date descending (farther away first)
      rawBookings.sort((a, b) {
        final aPending = (a["booking_status"] == "pending") ? 0 : 1;
        final bPending = (b["booking_status"] == "pending") ? 0 : 1;

        if (aPending != bPending) return aPending - bPending;

        final aDate = a["_date_sort"] as DateTime;
        final bDate = b["_date_sort"] as DateTime;
        return bDate.compareTo(aDate); // descending
      });


          setState(() {
            bookings = rawBookings;
            loading = false;
          });
        } else {
          setState(() {
            errorMessage = data["message"] ?? "حدث خطأ اثناء تحميل الحجوزات السابقة";
            loading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "حدث خطأ اثناء تحميل الحجوزات السابقة";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "حدث خطأ اثناء تحميل الحجوزات السابقة";
        loading = false;
      });
    }
  }


  

Widget _buildBookingCard(Map<String, dynamic> booking) {
  bool isBookingFinished() {
    try {
      final date = DateTime.parse(booking["booking_date"]);
      final end = booking["booking_end_time"]; 

      final endParts = end.split(":");
      final endTime = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(endParts[0]),
        int.parse(endParts[1]),
      );

      return DateTime.now().isAfter(endTime) &&
             booking["booking_status"] == "confirmed";
    } catch (_) {
      return false;
    }
  }

  final showReviewBanner =
      isBookingFinished() && booking["booking_is_reviewed"] == false;

  final fieldName = booking["field_name"] ?? "";
  final bookingDate = booking["booking_date_fmt"] ?? "";
  final startTime = booking["booking_start_time_fmt"] ?? "";
  final endTime = booking["booking_end_time_fmt"] ?? "";
  final remainingPrice = booking["booking_remaining_price"] ?? 0;
  final status = booking["booking_status_fmt"] ?? "غير معروف";
  final rawStatus = booking["booking_status"] ?? "";
  final bool isPending = rawStatus == "pending";

  String creationDate = "";

  try {
    final rawDate = booking["booking_creation_date"];
    if (rawDate != null && rawDate.isNotEmpty) {
      final parsedDate = DateTime.parse(rawDate).toLocal();
      String formatted =
          DateFormat("d MMMM y, HH:mm", "ar").format(parsedDate);

      creationDate = formatted.replaceAllMapped(
        RegExp(r'[٠١٢٣٤٥٦٧٨٩]'),
        (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString(),
      );
    }
  } catch (_) {
    creationDate = booking["booking_creation_date"] ?? "";
  }

  Color statusColor;
  switch (rawStatus) {
    case "confirmed":
      statusColor = Colors.redAccent;
      break;
    case "pending":
      statusColor = Colors.orange;
      break;
    default:
      statusColor = Colors.grey;
  }

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingDetailsPage(booking: booking),
        ),
      );
    },
    child: Stack(
      children: [
        // CARD
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Theme.of(context).colorScheme.onPrimary,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fieldName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPending) ...[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                   Icon(Icons.calendar_month,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      bookingDate,
                      style:
                         TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                   Icon(Icons.access_time_filled,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "$startTime - $endTime",
                      style:
                         TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                     Icon(Icons.payments_rounded,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "$remainingPrice د.ل",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                     Icon(Icons.history,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      creationDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (showReviewBanner)
          Positioned(
            left: 12,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.rate_review, size: 18, color: Colors.orange),
                  SizedBox(width: 6),
                  Text(
                    "تقييمك!",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
      ],
    ),
  );
}


  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 10),
            Text(
              "لا توجد حجوزات سابقة.",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(bookings[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("سجل الحجوزات",),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        ),
        body: SafeArea(child: _buildContent()),
      ),
    );
  }
}
