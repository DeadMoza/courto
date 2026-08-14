import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;

import 'field_booking_slots_page.dart';

class FieldCalendarPage extends StatefulWidget {
  final Map<String, dynamic> field;

  const FieldCalendarPage({super.key, required this.field});

  @override
  _FieldCalendarPageState createState() => _FieldCalendarPageState();
}

class _FieldCalendarPageState extends State<FieldCalendarPage> {
  Map<DateTime, List<dynamic>> bookingsByDate = {};
  // NEW: discounted slots indexed by date
  Map<DateTime, List<dynamic>> discountedSlotsByDate = {};

  // Standing admin rules that apply to every day, so they are not indexed by
  // date like the rest.
  List<dynamic> hiddenSlots = [];

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  bool loading = true;

  int get totalSlots => widget.field["slots_per_day"] ?? 10;

  // The bookings endpoint reports the field's seat count too. Trusting it over
  // whatever field map we were pushed with means the slots page is right even
  // when it was opened from a list that predates the column.
  int? _fetchedSlotSeats;

  Map<String, dynamic> get _field => _fetchedSlotSeats == null
      ? widget.field
      : {...widget.field, 'field_slot_seats': _fetchedSlotSeats};

  // Bookings this field can hold at once in one slot. A 6-cart karting track
  // needs 6x as many bookings before a day counts as full.
  int get _slotSeats {
    final raw = int.tryParse(_field['field_slot_seats']?.toString() ?? '');
    return (raw != null && raw >= 1) ? raw : 1;
  }

  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() => loading = true);
    final url =
        Uri.parse("${apiUrl}users/getfieldBookings/${widget.field['field_id']}");

    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print(res.body);

        // ── bookings ──────────────────────────────────────────────────────────
        final Map<DateTime, List<dynamic>> tempBookings = {};
        for (var booking in (data["bookings"] as List<dynamic>? ?? [])) {
          final day = DateTime.parse(booking["booking_date"]);
          final simpleDay = DateTime(day.year, day.month, day.day);
          (tempBookings[simpleDay] ??= []).add(booking);
        }

        // ── discounted slots (NEW) ────────────────────────────────────────────
        final Map<DateTime, List<dynamic>> tempDiscounts = {};
        for (var ds in (data["discounted_slots"] as List<dynamic>? ?? [])) {
          final day = DateTime.parse(ds["date"]);
          final simpleDay = DateTime(day.year, day.month, day.day);
          (tempDiscounts[simpleDay] ??= []).add(ds);
        }

        final seats = int.tryParse(data["slot_seats"]?.toString() ?? '');
        final hidden = (data["hidden_slots"] as List<dynamic>? ?? []);

        if (!mounted) return;
        setState(() {
          bookingsByDate = tempBookings;
          discountedSlotsByDate = tempDiscounts;
          hiddenSlots = hidden;
          if (seats != null && seats >= 1) _fetchedSlotSeats = seats;
          loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<dynamic> _getBookingsForDay(DateTime day) {
    final simpleDay = DateTime(day.year, day.month, day.day);
    return bookingsByDate[simpleDay] ?? [];
  }

  // NEW: returns discounted slots for a given calendar day
  List<dynamic> _getDiscountedSlotsForDay(DateTime day) {
    final simpleDay = DateTime(day.year, day.month, day.day);
    return discountedSlotsByDate[simpleDay] ?? [];
  }

  Color _fillForDay(DateTime day) {
    final bookings = _getBookingsForDay(day);
    if (bookings.length >= totalSlots * _slotSeats) return Colors.red.shade400;
    return Colors.transparent;
  }

  Widget _buildDayCell(
    DateTime day, {
    required Color fill,
    required Color border,
    Color? textColor,
    bool isSelected = false,
  }) {
    final numberColor = textColor ??
        (fill != Colors.transparent
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSecondary);

    final dayText =
        _isEnglish ? '${day.day}' : AppFormat.toEnglishNumbers('${day.day}');

    // NEW: check whether this day has any discount
    final hasDiscount = _getDiscountedSlotsForDay(day).isNotEmpty;

    return Center(
      child: SizedBox(
        width: 40,
        height: 52, // slightly taller to accommodate the badge below the circle
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Day circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: border,
                  width: border == Colors.transparent ? 0 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  dayText,
                  style: TextStyle(
                    color: numberColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Discount badge (NEW) – a small amber pill below the circle
            if (hasDiscount)
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isEnglish ? '%' : '٪',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final lastDay = today.add(const Duration(days: 7));

    return Directionality(
      textDirection: _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: loading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : ListView(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TableCalendar(
                        locale: _isEnglish ? 'en' : 'ar',
                        firstDay: today,
                        lastDay: lastDay,
                        focusedDay: focusedDay,
                        rowHeight: 58, // slightly taller rows to fit the badge
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        selectedDayPredicate: (day) =>
                            isSameDay(selectedDay, day),
                        onDaySelected: (selected, focused) async {
                          setState(() {
                            selectedDay = selected;
                            focusedDay = focused;
                          });

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FieldBookingSlotsPage(
                                field: _field,
                                date: selected,
                                bookings: _getBookingsForDay(selected),
                                // NEW: pass discounted slots for the selected day
                                discountedSlots:
                                    _getDiscountedSlotsForDay(selected),
                                hiddenSlots: hiddenSlots,
                              ),
                            ),
                          );

                          await fetchBookings();
                        },
                        calendarStyle: const CalendarStyle(
                          cellPadding: EdgeInsets.zero,
                          cellMargin: EdgeInsets.zero,
                          todayDecoration: BoxDecoration(),
                          selectedDecoration: BoxDecoration(),
                        ),
                        calendarBuilders: CalendarBuilders(
                          headerTitleBuilder: (context, day) {
                            final text = MaterialLocalizations.of(context)
                                .formatMonthYear(day);
                            final shown = _isEnglish
                                ? text
                                : AppFormat.toEnglishNumbers(text);
                            return Center(
                              child: Text(
                                shown,
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          },
                          defaultBuilder: (context, day, _) {
                            final fill = _fillForDay(day);
                            return _buildDayCell(
                              day,
                              fill: fill,
                              border: Colors.transparent,
                              isSelected: isSameDay(day, selectedDay),
                            );
                          },
                          outsideBuilder: (context, day, _) {
                            final fill = _fillForDay(day);
                            return _buildDayCell(
                              day,
                              fill: fill.withOpacity(0.25),
                              border: Colors.transparent,
                              textColor: Colors.black45,
                            );
                          },
                          todayBuilder: (context, day, _) {
                            final fill = _fillForDay(day);
                            return _buildDayCell(
                              day,
                              fill: fill,
                              border: Theme.of(context).colorScheme.onSecondary,
                              isSelected: isSameDay(day, selectedDay),
                            );
                          },
                          selectedBuilder: (context, day, _) {
                            final fill = _fillForDay(day);
                            return _buildDayCell(
                              day,
                              fill: fill,
                              border: Colors.black,
                              isSelected: true,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}