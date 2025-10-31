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
    final fieldName = booking["field_name"] ?? "";
    final bookingDate = booking["booking_date_fmt"] ?? "";
    final startTime = booking["booking_start_time_fmt"] ?? "";
    final endTime = booking["booking_end_time_fmt"] ?? "";
    final remainingPrice = booking["booking_remaining_price"] ?? 0;
    final status = booking["booking_status_fmt"] ?? "غير معروف";
    final rawStatus = booking["booking_status"] ?? "";
String creationDate = "";
try {
  final rawDate = booking["booking_creation_date"];
  if (rawDate != null && rawDate.isNotEmpty) {
    final parsedDate = DateTime.parse(rawDate);


    String formatted = DateFormat("d MMMM y, HH:mm", "ar").format(parsedDate);

    // Replace Arabic-Indic digits with Latin digits
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
        statusColor = Colors.red;
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
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
              // Field name + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fieldName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
      
              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    bookingDate,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
      
              // Time
              Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "$startTime - $endTime",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
      
              // Price
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "$remainingPrice د.ل",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Creation date
                            Row(
                children: [
                  const Icon(Icons.schedule_send_outlined,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    creationDate,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.redAccent),
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
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          title: const Text("سجل الحجوزات",),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(child: _buildContent()),
      ),
    );
  }
}
