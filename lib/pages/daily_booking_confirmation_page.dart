import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/services/auth_service.dart'; // assuming AuthService is defined here
import 'dart:ui' as ui;

class DailyBookingConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> field;
  final DateTime date;
  final List<Map<String, dynamic>> slots;
  final double totalBookingPrice;
  final double remainingPaymentToOwner;
  final String frequency;
  final int userId;

  const DailyBookingConfirmationPage({
    super.key,
    required this.field,
    required this.date,
    required this.slots,
    required this.totalBookingPrice,
    required this.remainingPaymentToOwner,
    required this.frequency,
    required this.userId,
  });

  @override
  State<DailyBookingConfirmationPage> createState() =>
      _DailyBookingConfirmationPageState();
}

class _DailyBookingConfirmationPageState
    extends State<DailyBookingConfirmationPage> {
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, DateTime>> _mergeConsecutiveSlots() {
    if (widget.slots.isEmpty) return [];

    List<Map<String, DateTime>> merged = [];
    widget.slots.sort((a, b) =>
        DateTime.parse(a['start']).compareTo(DateTime.parse(b['start'])));

    DateTime? currentStart;
    DateTime? currentEnd;

    for (final s in widget.slots) {
      final start = DateTime.parse(s['start']);
      final end = DateTime.parse(s['end']);

      if (currentStart == null) {
        currentStart = start;
        currentEnd = end;
      } else if (start.isAtSameMomentAs(currentEnd!)) {
        currentEnd = end;
      } else {
        merged.add({'start': currentStart, 'end': currentEnd});
        currentStart = start;
        currentEnd = end;
      }
    }

    if (currentStart != null && currentEnd != null) {
      merged.add({'start': currentStart, 'end': currentEnd});
    }

    return merged;
  }

  Future<void> _bookField() async {
    final mergedRanges = _mergeConsecutiveSlots();
    if (mergedRanges.isEmpty) return;

    final firstRange = mergedRanges.first;
    final startTime = firstRange['start']!;
    final endTime = firstRange['end']!;
    final note = _noteController.text;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse('${apiUrl}users/bookField');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
        },
        body: jsonEncode({
          "field_id": widget.field['field_id'],
          "user_id": widget.userId,
          "booking_date": widget.date.toIso8601String().split('T').first,
          "start_time":
              "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}",
          "end_time":
              "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}",
          "total_price": widget.totalBookingPrice,
          "notes": note,

          //notification data
          "client_id": widget.field["field_client_id"],
          "field_name": widget.field["field_name"],

        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم ارسال طلب الحجز الى صاحب الملعب."), backgroundColor: Colors.red,),
        );
        Navigator.popUntil(context, ModalRoute.withName("/"));
        Navigator.pushNamed(context, "/bookingHistoryPage");
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'فشل تأكيد الحجز';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red,),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red,),
      );
    }
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: const Text(
          "تأكيد الحجز",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          "هل تريد تأكيد هذا الحجز؟",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close the confirmation popup
              _bookField(); // 🔥 Call API here
            },
            child: const Text(
              "تأكيد",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mergedRanges = _mergeConsecutiveSlots();

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context, title: "تأكيد الحجز"),
        backgroundColor: Colors.red.shade50,
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "سعر الحجز:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${widget.totalBookingPrice.toStringAsFixed(2)} د.ل",
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmBooking,
                    child: const Text(
                      "تأكيد الحجز",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.field['field_name'] ?? 'ملعب غير معروف',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        AppFormat.formatDateArabic(widget.date),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mergedRanges.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "${AppFormat.formatTime(r['start']!)} - ${AppFormat.formatTime(r['end']!)}",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 30, thickness: 1.2),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber, size: 20),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
"يمكنك إلغاء الحجز بعد مرور ساعة واحدة بالضبط إذا لم يجيب صاحب الملعب على طلبك. \nولا يمكنك حجز ملعب آخر أثناء وجود حجز معلق. \n\nسيقوم صاحب الملعب بالرد على طلبك بالموافقة أو الرفض في اقرب وقت ممكن.\n\nسيتم دفع هذا المبلغ الآن كرسوم حجز فقط، وسيتعين عليك دفع المبلغ المتبقي لصاحب الملعب بعد الانتهاء من اللعب.",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "المبلغ المتبقي: ${widget.remainingPaymentToOwner.toStringAsFixed(2)} د.ل",
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ملاحظات لصاحب الملعب:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
