import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/services/auth_service.dart';
import 'dart:ui' as ui;

class MonthlyBookingConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> field;
  final DateTime date;
  final List<Map<String, dynamic>> slots;
  final String frequency;
  final int userId;
  final double totalBookingPrice;
  final double remainingPaymentToOwner;

  const MonthlyBookingConfirmationPage({
    super.key,
    required this.field,
    required this.date,
    required this.slots,
    required this.frequency,
    required this.userId,
    required this.totalBookingPrice,
    required this.remainingPaymentToOwner,

    
  });

  @override
  State<MonthlyBookingConfirmationPage> createState() =>
      _MonthlyBookingConfirmationPageState();
      
}

class _MonthlyBookingConfirmationPageState
    extends State<MonthlyBookingConfirmationPage> {
  final TextEditingController _noteController = TextEditingController();
  final apiUrl = dotenv.env['API_URL'];

/// Merge consecutive booked time slots and handle cross-midnight times
List<Map<String, DateTime>> _mergeConsecutiveSlots() {
  if (widget.slots.isEmpty) return [];

  List<Map<String, DateTime>> merged = [];
  widget.slots.sort((a, b) =>
      DateTime.parse(a['start']).compareTo(DateTime.parse(b['start'])));

  DateTime? currentStart;
  DateTime? currentEnd;

  for (final s in widget.slots) {
    DateTime start = DateTime.parse(s['start']);
    DateTime end = DateTime.parse(s['end']);

    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

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
  void _showMidnightInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible( 
                child: Text(
                  "تنبيه بخصوص التوقيت",
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18,),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          content: const Text(
            "إذا كانت فترة الحجز تمتد إلى ما بعد منتصف الليل (12:00 ص)، فإن تلك الساعات تقع فعليًا في اليوم التالي للتاريخ المحدد في الأعلى، وليس في التاريخ الحالي.",
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("حسناً", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
            ),
          ],
        );
      },
    );
  }


  Future<void> _bookField() async {
    final mergedRanges = _mergeConsecutiveSlots();
    if (mergedRanges.isEmpty) return;

    final firstRange = mergedRanges.first;
    final startTime = firstRange['start']!;
    final endTime = firstRange['end']!;
    final note = _noteController.text;  

    final totalBookingPrice = widget.totalBookingPrice * 4;
    final remaining =  widget.remainingPaymentToOwner * 4;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uri = Uri.parse('${apiUrl}users/bookFieldMonthly');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
        body: jsonEncode({
          "field_id": widget.field['field_id'],
          "user_id": widget.userId,
          "booking_date": widget.date.toIso8601String().split('T').first,
          "start_time": "${startTime.hour.toString().padLeft(2, '0')}:00",
          "end_time": "${endTime.hour.toString().padLeft(2, '0')}:00",
          "booking_price": totalBookingPrice,
          "remaining_price": remaining,
          "notes": note,
          "client_id": widget.field["field_client_id"],
          "field_name": widget.field["field_name"],
        }),

      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم ارسال طلب الحجز الشهري إلى صاحب الملعب."),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, "/bookingHistoryPage");

      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'فشل تأكيد الحجز';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("حدث خطأ: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          "تأكيد الحجز الشهري",
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: const Text(
          "هل تريد تأكيد هذا الحجز لمدة 4 ايام؟",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("إلغاء", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _bookField();
            },
            child: const Text("تأكيد", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mergedRanges = _mergeConsecutiveSlots();

    final totalBookingPrice = widget.totalBookingPrice * 4;
    final remaining =  widget.remainingPaymentToOwner * 4;

    final date2 = widget.date.add(const Duration(days: 7));
    final date3 = widget.date.add(const Duration(days: 14));
    final date4 = widget.date.add(const Duration(days: 21));

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
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
                    const Text("سعر الحجز",
                        style: TextStyle(fontSize: 16)),
                    Text(
                      "${totalBookingPrice.toStringAsFixed(2)} د.ل",
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("المبلغ المتبقي لصاحب الملعب:",
                        style: TextStyle(fontSize: 16)),
                    Text(
                      "${remaining.toStringAsFixed(2)} د.ل",
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmBooking,
                    child: const Text(
                      "تأكيد الحجز الشهري",
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
            color: Theme.of(context).colorScheme.onPrimary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.field['field_name'] ?? 'ملعب غير معروف',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${AppFormat.formatDateArabic(widget.date)} - ${AppFormat.formatDateArabic(date2)} - ${AppFormat.formatDateArabic(date3)} - ${AppFormat.formatDateArabic(date4)}",
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSecondary,
                            height: 1.4,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),

                  const SizedBox(height: 8),
if (mergedRanges.isNotEmpty)
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Times on the left (takes remaining width)
      Expanded(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mergedRanges.map((r) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                "${AppFormat.formatTime(r['start']!)} - ${AppFormat.formatTime(r['end']!)}",
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            );
          }).toList(),
        ),
      ),

      const SizedBox(width: 8),

      // Midnight info icon on the right
      IconButton(
        icon: Icon(Icons.nights_stay,
            color: Theme.of(context).colorScheme.primary, size: 24),
        onPressed: () => _showMidnightInfoDialog(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: "تنبيه بخصوص التوقيت",
      ),
    ],
  ),

                  const Divider(height: 30, thickness: 1.2),
                  Column(
                    children: [
                                        Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                           Icon(Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary, size: 20),
                            const SizedBox(width: 5),
Flexible(
                              child: RichText(
  text:  TextSpan(
    style: TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSecondary,
      fontFamily: "Changa"
    ),
    children: [
      const TextSpan(
        text:
            "في حالة بقاء حجزك قيد الانتظار فيمكنك الغاء الحجز بعد مرور 20 دقيقة بالضبط.\n"
            "ولا يمكنك حجز ملعب آخر أثناء وجود حجز قيد الانتظار.\n\n"
            "سيقوم مدير الملعب بالرد على طلبك بالموافقة أو الرفض في اقرب وقت ممكن.\n\n"
            "سيتم خصم مبلغ الحجز ",
      ),
      TextSpan(
        text: "$totalBookingPrice د.ل",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      const TextSpan(
        text: " في لحظة قبول مدير الملعب لطلبك، وسيتعين عليك دفع ",
      ),
      TextSpan(
        text: "${remaining.toStringAsFixed(2)} د.ل",
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      const TextSpan(
        text: " لمدير الملعب بعد او قبل الانتهاء من اللعب.",
      ),
    ],
  ),
)

                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                  const SizedBox(height: 10),
                       Text(
                        "ملاحظات لصاحب الملعب:",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary, width: 1.5),
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
