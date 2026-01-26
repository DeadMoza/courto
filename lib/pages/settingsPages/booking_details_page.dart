import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:courto/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  bool isReviewSubmitting = false;

  // Inline review form
  bool showRatingForm = false;
  int selectedScore = 3;

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
    const twentyMinutes = Duration(minutes: 20);

    if (elapsed >= twentyMinutes) {
      setState(() => canCancel = true);
    } else {
      timeRemaining = twentyMinutes - elapsed;
      setState(() => canCancel = false);

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final remaining = twentyMinutes - now.difference(creationDate);
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
          content: Text("لا يمكن إلغاء الحجز إلا بعد 20 دقيقة من إنشائه."),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"]), backgroundColor: Theme.of(context).colorScheme.primary),
        );
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["error"] ?? "حدث خطأ غير معروف"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في الاتصال: ${e.toString()}"), backgroundColor: Theme.of(context).colorScheme.primary),
      );
    } finally {
      setState(() => isCancelling = false);
    }
  }

  Future<void> submitReview(int score) async {
    final userId = AuthService.userData?["id"];
    final fieldId = widget.booking["field_id"];
    final bookingId = widget.booking["booking_id"];

    if (fieldId == null || score < 1 || score > 5) return;

    setState(() => isReviewSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse("${apiUrl}users/postReview"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
        body: jsonEncode({
          "score": score,
          "user_id": userId,
          "field_id": fieldId,
          "booking_id": bookingId
        }),
      );

      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"] ?? "تم إرسال التقييم"),
          backgroundColor: data["success"] == true ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary,
        ),
      );

      if (data["success"] == true) {
        setState(() {
          widget.booking["booking_is_reviewed"] = true;
          showRatingForm = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في إرسال التقييم: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => isReviewSubmitting = false);
    }
  }

  bool get showLeaveReviewButton {
    final isReviewed = widget.booking["booking_is_reviewed"] == true;
    final status = widget.booking["booking_status"];
    final bookingDateStr = widget.booking["booking_date"];
    if (bookingDateStr == null) return false;

    final bookingDate = DateTime.parse(bookingDateStr).toLocal();
    return !isReviewed && status == "confirmed" && DateTime.now().isAfter(bookingDate);
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final fieldName = booking["field_name"] ?? "ملعب غير معروف";
    final bookingDate = booking["booking_date_fmt"] ?? "--";
    final startTime = booking["booking_start_time_fmt"] ?? "--";
    final endTime = booking["booking_end_time_fmt"] ?? "--";
    final bookingPrice = booking["booking_price"];
    final remainingPrice = booking["booking_remaining_price"];
    final status = booking["booking_status"];
    final isPending = status == "pending";
    final isMonthly = booking["booking_is_monthly"] == true;
    final period = booking["booking_period"] ?? 4;

    String creationDate = "";
    try {
      final rawDate = booking["booking_creation_date"];
      if (rawDate != null && rawDate.isNotEmpty) {
        final parsedDate = DateTime.parse(rawDate).toLocal();
        String formatted = DateFormat("d MMMM y, HH:mm", "ar").format(parsedDate);
        creationDate = formatted.replaceAllMapped(
          RegExp(r'[٠١٢٣٤٥٦٧٨٩]'),
          (m) => '٠١٢٣٤٥٦٧٨٩'.indexOf(m[0]!).toString(),
        );
      }
    } catch (_) {
      creationDate = booking["booking_creation_date"] ?? "";
    }

    List<String> monthlyDates = [];
    if (isMonthly && booking["booking_date"] != null) {
      try {
        final firstDate = DateTime.parse(booking["booking_date"]);
        for (int i = 0; i < period; i++) {
          final nextDate = firstDate.add(Duration(days: 7 * i));
          monthlyDates.add(AppFormat.formatDateArabic(nextDate));
        }
      } catch (_) {
        monthlyDates = ["خطأ في تحميل المواعيد"];
      }
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("تفاصيل الحجز", style: TextStyle(color: Colors.white)),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Card(
              color: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fieldName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              status == "pending" ? Icons.hourglass_bottom : Icons.check_circle,
                              color: status == "pending" ? Colors.orange.shade700 : Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status == "pending" ? "قيد الانتظار" : "مؤكد",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == "pending" ? Colors.orange.shade700 : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "رمز الحجز: ${booking["booking_id"] ?? '--'}",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Theme.of(context).colorScheme.primary)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isMonthly)
                            _buildIconTextRow(
                              icon: Icons.calendar_month,
                              text: bookingDate,
                              isCentered: true,
                              bold: true,
                              size: 16
                            ),
                          
                          if (isMonthly && monthlyDates.isNotEmpty)
                            Column(
                              children: [
                                const Text(
                                  "مواعيد الحجز:", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)
                                ),
                                const SizedBox(height: 10),
                                ...monthlyDates.map((d) => _buildIconTextRow(
                                  icon: Icons.event_repeat,
                                  text: d,
                                  isCentered: true,
                                  size: 14,
                                  padding: const EdgeInsets.only(bottom: 4)
                                )),
                                const SizedBox(height: 10),
                              ],
                            ),

                          _buildIconTextRow(
                            icon: Icons.access_time_filled,
                            text: "$startTime - $endTime",
                            isCentered: true,
                            bold: true,
                            size: 18
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    const Text("التفاصيل المالية:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      label: "سعر الحجز",
                      value: "$bookingPrice د.ل",
                      valueColor: Theme.of(context).colorScheme.onSecondary
                    ),
                    _buildDetailRow(
                      label: "السعر المتبقي للدفع",
                      value: "$remainingPrice د.ل",
                      valueColor: Colors.redAccent,
                      isBold: true,
                      size: 18,
                    ),

                    const Divider(height: 30, thickness: 1),

                   Text(
                      "تاريخ إنشاء الحجز:", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSecondary)
                    ),
                    const SizedBox(height: 5),
                    _buildIconTextRow(
                      icon: Icons.history, 
                      text: creationDate, 
                    ),

// --- Inline Review Section with Animation and 5px Border Radius ---
if (showLeaveReviewButton)
  Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5), // 5px radius
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() => showRatingForm = !showRatingForm);
            },
            icon: Icon(showRatingForm ? Icons.rate_review : Icons.keyboard_arrow_down, color: showRatingForm ? Colors.white : Theme.of(context).colorScheme.onSecondary),
            label: Text(
              showRatingForm ? "إغلاق التقييم" : "ترك تقييم",
              style: TextStyle(color: showRatingForm ? Colors.white : Theme.of(context).colorScheme.onSecondary, fontFamily: 'Changa'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: showRatingForm ? Theme.of(context).colorScheme.primary : Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: "Changa",
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5), // 5px radius
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const Text("كيف كانت الاجواء؟"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedScore ? Icons.star : Icons.star_border,
                      color: Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() => selectedScore = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: isReviewSubmitting
                    ? null
                    : () => submitReview(selectedScore),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // 5px radius
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isReviewSubmitting
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "إرسال التقييم",
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          crossFadeState: showRatingForm ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    ),
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
                    : () => cancelBooking(),
                backgroundColor: canCancel ? Colors.redAccent : Colors.amber,
                icon: isCancelling
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Icon(Icons.cancel, color: Theme.of(context).colorScheme.onPrimary),
                label: Text(
                  isCancelling
                      ? "جارٍ الإلغاء..."
                      : canCancel ? "إلغاء الحجز" : "الإلغاء متاح بعد ${ _formatDuration(timeRemaining)}",
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
                ),
              )
            : null,
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildDetailRow({
    required String label,
    required String value,
    Color valueColor = Colors.black,
    bool isBold = false,
    double size = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: size,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
            textDirection: ui.TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildIconTextRow({
    required IconData icon,
    required String text,
    bool isCentered = false,
    bool bold = false,
    double size = 16,
    EdgeInsetsGeometry padding = EdgeInsets.zero
  }) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: isCentered ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: size),
            textDirection: ui.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
