import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/services/auth_service.dart';
import 'package:courto/l10n/app_localizations.dart';

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

class _DailyBookingConfirmationPageState extends State<DailyBookingConfirmationPage> {
  final TextEditingController _noteController = TextEditingController();
  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<Map<String, DateTime>> _mergeConsecutiveSlots() {
    if (widget.slots.isEmpty) return [];

    final merged = <Map<String, DateTime>>[];
    widget.slots.sort(
      (a, b) => DateTime.parse(a['start']).compareTo(DateTime.parse(b['start'])),
    );

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
    final t = AppLocalizations.of(context)!;

    final mergedRanges = _mergeConsecutiveSlots();
    if (mergedRanges.isEmpty) return;

    final earliestStart = mergedRanges.first['start']!;
    final latestEnd = mergedRanges.last['end']!;
    final note = _noteController.text;

    String formatTime(DateTime dt) =>
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    final bookingDate = DateTime(widget.date.year, widget.date.month, widget.date.day);

    final startTimeStr = formatTime(earliestStart);
    final endTimeStr = formatTime(latestEnd);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      ),
    );

    try {
      final uri = Uri.parse('${apiUrl}users/bookField');
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
          "booking_date": bookingDate.toIso8601String().split('T').first,
          "start_time": startTimeStr,
          "end_time": endTimeStr,
          "booking_price": widget.totalBookingPrice,
          "remaining_price": widget.remainingPaymentToOwner,
          "notes": note,
          "client_id": widget.field["field_client_id"],
          "field_name": widget.field["field_name"],
        }),
      );

      if (mounted) Navigator.pop(context); // close loader

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? "Booking request sent to the field owner." : t.bookingRequestSent,
              textDirection: _dir,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pushReplacementNamed(context, "/bookingHistoryPage");
      } else {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? (_isEnglish ? "Booking confirmation failed" : t.bookingConfirmFailed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.toString(), textDirection: _dir),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? "Error: $e" : "${AppLocalizations.of(context)!.errorWithMessage(e.toString())}",
            textDirection: _dir,
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _confirmBooking() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: _dir,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Text(
            _isEnglish ? "Confirm booking" : t.dailyConfirmTitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          content: Text(
            _isEnglish ? "Do you want to confirm this booking?" : t.confirmBookingQuestion,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isEnglish ? "Cancel" : t.cancel,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _bookField();
              },
              child: Text(
                _isEnglish ? "Confirm" : t.confirm,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMidnightInfoDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: _dir,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Text(
            _isEnglish ? "Time notice" : t.midnightInfoTitle,
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            _isEnglish
                ? "If your booking extends past midnight (12:00 AM), those hours belong to the next day, not the selected date."
                : t.midnightInfoBody,
            textAlign: _isEnglish ? TextAlign.left : TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isEnglish ? "OK" : t.ok,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final mergedRanges = _mergeConsecutiveSlots();

    final fieldName = (widget.field['field_name'] ?? (_isEnglish ? "Unknown field" : t.unknownField)).toString();

    final bookingPriceText = _isEnglish ? "Booking price:" : t.bookingPriceLabel;
    final remainingText = _isEnglish ? "Remaining amount:" : t.remainingAmountLabel;
    final confirmText = _isEnglish ? "Confirm booking" : t.confirmBooking;

    final currency = _isEnglish ? "LYD" : t.currencyLYD;

    return Directionality(
      textDirection: _dir,
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
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bookingPriceText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${widget.totalBookingPrice.toStringAsFixed(2)} $currency",
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      remainingText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${widget.remainingPaymentToOwner.toStringAsFixed(2)} $currency",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _confirmBooking,
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            _isEnglish
                                ? "${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}"
                                : AppFormat.formatDateArabic(widget.date),
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
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
                                border: Border.all(color: Theme.of(context).colorScheme.primary),
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
                      Tooltip(
                        message: _isEnglish ? "Time notice" : t.timeTooltip,
                        child: IconButton(
                          icon: Icon(Icons.nights_stay,
                              color: Theme.of(context).colorScheme.primary, size: 24),
                          onPressed: _showMidnightInfoDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 30, thickness: 1.2),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            textDirection: _dir,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14.5,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontFamily: "Changa",
                              ),
                              children: [
                                TextSpan(text: _isEnglish ? (
                                  "If your booking stays pending, you can cancel it exactly after 20 minutes.\n"
                                  "You can't book another field while you have a pending booking.\n\n"
                                  "The field manager will accept or reject your request as soon as possible.\n\n"
                                  "The booking amount "
                                ) : t.pendingInfoPrefix),
                                TextSpan(
                                  text: "${widget.totalBookingPrice.toStringAsFixed(2)} $currency",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: _isEnglish ? " will be charged when the request is accepted, and you'll need to pay " : t.pendingInfoMiddle),
                                TextSpan(
                                  text: "${widget.remainingPaymentToOwner.toStringAsFixed(2)} $currency",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(text: _isEnglish ? " to the field manager before or after playing." : t.pendingInfoSuffix),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    _isEnglish ? "Notes to field manager:" : t.notesToOwner,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    textDirection: _dir,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        ),
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
