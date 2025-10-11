import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'booking_history_page.dart';

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
        },
        body: jsonEncode({"booking_id": bookingId, "user_id": userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["message"] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BookingsHistoryPage()),
        );
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
    final price = booking["booking_total_price"] ?? "--";
    final status = booking["booking_status"];
    final isPending = status == "pending";

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        Text("رمز الحجز: ${booking["booking_id"] ?? '--'}"),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Centered Date, Time & Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(bookingDate),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("$startTime - $endTime"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "السعر المتبقي: $price د.ل",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
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
                    : const Icon(Icons.cancel,),
                label: Text(
                  isCancelling ? "جارٍ الإلغاء..." : "إلغاء الحجز",
                ),
              )
            : null,
      ),
    );
  }
}
