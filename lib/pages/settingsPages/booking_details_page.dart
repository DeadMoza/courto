import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class BookingDetailsPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  bool isCancelling = false;
  bool canCancel = false;
  Duration timeRemaining = Duration.zero;
  Timer? countdownTimer;
  final apiUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();
    _checkCancelEligibility();
  }

  void _checkCancelEligibility() {
    final creationDateStr = widget.booking["booking_creation_date"];
    if (creationDateStr == null) return;

    final creationDate = DateTime.parse(creationDateStr).toLocal();
    final now = DateTime.now();
    final elapsed = now.difference(creationDate);
    const oneHour = Duration(hours: 1);

    if (elapsed >= oneHour) {
      setState(() => canCancel = true);
    } else {
      timeRemaining = oneHour - elapsed;
      setState(() => canCancel = false);

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final remaining = oneHour - now.difference(creationDate);
        if (remaining.isNegative) {
          timer.cancel();
          setState(() {
            canCancel = true;
            timeRemaining = Duration.zero;
          });
        } else {
          setState(() => timeRemaining = remaining);
        }
      });
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> cancelBooking() async {
    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("يمكنك إلغاء الحجز بعد ${_formatDuration(timeRemaining)} دقيقة"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الإلغاء"),
        content: const Text("هل أنت متأكد أنك تريد إلغاء هذا الحجز؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("لا")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("نعم")),
        ],
      ),
    );

    if (confirm != true) return;

    final bookingId = widget.booking["booking_id"];
    final userId = AuthService.userData?["id"];
    final token = AuthService.token;

    setState(() => isCancelling = true);

    try {
      final response = await http.post(
        Uri.parse("${apiUrl}users/cancelBooking"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
        body: jsonEncode({"booking_id": bookingId, "user_id": userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["message"] != null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"]), backgroundColor: Colors.redAccent),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "حدث خطأ غير معروف"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final fieldName = booking["field_name"] ?? "ملعب غير معروف";
    final bookingDate = booking["booking_date_fmt"] ?? "--";
    final startTime = booking["booking_start_time_fmt"] ?? "--";
    final endTime = booking["booking_end_time_fmt"] ?? "--";
    final bookingPrice = booking["booking_price"];
    final remainingPrice = booking["booking_remaining_price"] ?? "--";
    final status = booking["booking_status"];
    final isPending = status == "pending";
    final isMonthly = booking["booking_is_monthly"] == true;
    final period = booking["booking_period"] ?? 4; 


    List<String> monthlyDates = [];
    if (isMonthly && booking["booking_date"] != null) {
      try {
        final firstDate = DateTime.parse(booking["booking_date"]);
        for (int i = 0; i < period; i++) {
          final nextDate = firstDate.add(Duration(days: 7 * i));
          monthlyDates.add("${nextDate.day}-${nextDate.month}-${nextDate.year}");
        }
      } catch (_) {}
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text("تفاصيل الحجز", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Name
                    Text(
                      fieldName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status & Booking ID
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == "pending" ? Icons.hourglass_bottom : Icons.check_circle,
                              color: status == "pending" ? Colors.orange : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              status == "pending" ? "قيد الانتظار" : "مؤكد",
                              style: TextStyle(
                                color: status == "pending" ? Colors.orange : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "رمز الحجز: ${booking["booking_id"] ?? '--'}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    if (isMonthly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          "هذا الحجز شهري",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent),
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (isMonthly && monthlyDates.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("مواعيد الحجز:", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...monthlyDates.map((d) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 6),
                                    Text(d, style: const TextStyle(color: Colors.black54)),
                                    const SizedBox(height: 6,),
                                  ],
                                ),
                              )),
                              Text(startTime + " - " + endTime),
                          const Divider(),
                        ],
                      ),

                    // Date, Time & Price
                    if (!isMonthly)
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Text(bookingDate, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text("$startTime - $endTime",
                                  style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                        ],
                      ),

                    const SizedBox(height: 10),

                    Text(
                      "سعر الحجز: $bookingPrice د.ل",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "السعر المتبقي: $remainingPrice د.ل",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: isPending
            ? FloatingActionButton.extended(
                onPressed: isCancelling
                    ? null
                    : () {
                        if (canCancel) {
                          cancelBooking();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "يمكنك إلغاء الحجز بعد ${_formatDuration(timeRemaining)} دقيقة"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                backgroundColor: canCancel ? Colors.red : Colors.amber,
                icon: isCancelling
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cancel, color: Colors.white),
                label: Text(
                  isCancelling ? "جارٍ الإلغاء..." : "إلغاء الحجز",
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : null,
      ),
    );
  }
}
