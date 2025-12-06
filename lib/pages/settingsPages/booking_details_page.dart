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
        SnackBar(content: Text("خطأ في الاتصال: ${e.toString()}"), backgroundColor: Colors.red),
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
          backgroundColor: data["success"] == true ? Colors.redAccent : Colors.redAccent,
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
        SnackBar(content: Text("خطأ في إرسال التقييم: ${e.toString()}"), backgroundColor: Colors.red),
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
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text("تفاصيل الحجز", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Card(
              color: Colors.white,
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
                        color: Colors.red,
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
                              color: status == "pending" ? Colors.orange.shade700 : Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status == "pending" ? "قيد الانتظار" : "مؤكد",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == "pending" ? Colors.orange.shade700 : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "رمز الحجز: ${booking["booking_id"] ?? '--'}",
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    if (isMonthly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.redAccent.shade100),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            "هذا الحجز شهري متكرر",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent),
                          ),
                        ),
                      ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.red.shade100)
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)
                                ),
                                const SizedBox(height: 10),
                                ...monthlyDates.map((d) => _buildIconTextRow(
                                  icon: Icons.event_repeat,
                                  text: d,
                                  isCentered: true,
                                  color: Colors.black87,
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
                      valueColor: Colors.black54
                    ),
                    _buildDetailRow(
                      label: "السعر المتبقي للدفع",
                      value: "$remainingPrice د.ل",
                      valueColor: Colors.red,
                      isBold: true,
                      size: 18,
                    ),

                    const Divider(height: 30, thickness: 1),

                    const Text(
                      "تاريخ إنشاء الحجز:", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)
                    ),
                    const SizedBox(height: 5),
                    _buildIconTextRow(
                      icon: Icons.history, 
                      text: creationDate, 
                      color: Colors.black54
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
            icon: Icon(showRatingForm ? Icons.rate_review : Icons.keyboard_arrow_down, color: showRatingForm ? Colors.white : Colors.black54),
            label: Text(
              showRatingForm ? "إغلاق التقييم" : "ترك تقييم",
              style: TextStyle(color: showRatingForm ? Colors.white : Colors.black54, fontFamily: 'Changa'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: showRatingForm ? Colors.redAccent : Colors.orangeAccent,
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
                      color: Colors.redAccent,
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
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // 5px radius
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isReviewSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "إرسال التقييم",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                backgroundColor: canCancel ? Colors.red : Colors.amber,
                icon: isCancelling
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.cancel, color: Colors.white),
                label: Text(
                  isCancelling
                      ? "جارٍ الإلغاء..."
                      : canCancel ? "إلغاء الحجز" : "الإلغاء متاح بعد ${ _formatDuration(timeRemaining)}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontSize: 16, color: Colors.black54),
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
    Color iconColor = Colors.redAccent,
    Color color = Colors.black,
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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: size),
            textDirection: ui.TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
