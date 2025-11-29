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

  @override
  void initState() {
    super.initState();
    _checkCancelEligibility();
  }

  // --- Cancellation Logic ---

  void _checkCancelEligibility() {
    final creationDateStr = widget.booking["booking_creation_date"];
    if (creationDateStr == null) return;

    // Use toLocal() to treat the stored date string as local time for comparison.
    // NOTE: It is generally best practice to store dates as UTC and convert to local for display.
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
    // Format to "MM:SS"
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> cancelBooking() async {
    // Show countdown on press if not eligible
    if (!canCancel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("لا يمكن إلغاء الحجز إلا بعد 20 دقيقة من إنشائه."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation Dialog
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

    // API Call Logic
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
        // Navigate back to the root (e.g., home or main list)
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

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final fieldName = booking["field_name"] ?? "ملعب غير معروف";
    final bookingDate = booking["booking_date_fmt"] ?? "--";
    final startTime = booking["booking_start_time_fmt"] ?? "--";
    final endTime = booking["booking_end_time_fmt"] ?? "--";
    final bookingPrice = booking["booking_price"]; // Format price
    final remainingPrice = booking["booking_remaining_price"]; // Format price
    final status = booking["booking_status"];
    final isPending = status == "pending";
    final isMonthly = booking["booking_is_monthly"] == true;
    final period = booking["booking_period"] ?? 4;
String creationDate = "";
try {
  final rawDate = booking["booking_creation_date"];
  if (rawDate != null && rawDate.isNotEmpty) {
    // Parse as UTC, then convert to local
    final parsedDate = DateTime.parse(rawDate).toLocal();

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

    // Calculate monthly booking dates
    List<String> monthlyDates = [];
    if (isMonthly && booking["booking_date"] != null) {
      try {
        final firstDate = DateTime.parse(booking["booking_date"]);
        for (int i = 0; i < period; i++) {
          final nextDate = firstDate.add(Duration(days: 7 * i));
          // Format each date
          monthlyDates.add(AppFormat.formatDateArabic(nextDate));
        }
      } catch (_) {
        monthlyDates = ["خطأ في تحميل المواعيد"];
      }
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red.shade50, // Slightly lighter background
        appBar: AppBar(
          title: const Text("تفاصيل الحجز", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent, // Darker red AppBar
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)), // Rounded corners
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Field Name & Status ---
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
                        // Status Badge
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
                        // Booking ID
                        Text(
                          "رمز الحجز: ${booking["booking_id"] ?? '--'}",
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(height: 30, thickness: 1),

                    // --- Monthly Tag ---
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

                    // --- Highlighted Booking Times/Dates (Main Detail) ---
                    Container(
                      width: double.infinity, // Full width
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, // Reddish background
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.red.shade100)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Center Alignment
                        children: [
                          // Date(s)
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

                          // Time Range
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

                    // --- Financial Details ---
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

                    // --- Creation Date (Repositioned) ---
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
                  ],
                ),
              ),
            ),
          ),
        ),
        // --- Floating Action Button for Cancellation ---
        floatingActionButton: isPending
            ? FloatingActionButton.extended(
                onPressed: isCancelling
                    ? null
                    : () => cancelBooking(), // Simplified press handler
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
                      : canCancel ? "إلغاء الحجز" : "الإلغاء متاح بعد ${ _formatDuration(timeRemaining)}", // Dynamic label
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
            textDirection: ui.TextDirection.ltr, // Ensure numbers display correctly
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