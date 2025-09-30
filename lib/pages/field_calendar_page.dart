import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:flutter/material.dart';
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
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  bool loading = true;

  int get totalSlots => widget.field["slots_per_day"] ?? 10; 

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    setState(() => loading = true);
    final url = Uri.parse("${apiUrl}users/getfieldBookings/${widget.field['field_id']}");

    try {
      final res = await http.get(url, headers: {"Content-Type": "application/json"});
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final Map<DateTime, List<dynamic>> temp = {};

        for (var booking in data["bookings"]) {
          final day = DateTime.parse(booking["booking_date"]);
          final simpleDay = DateTime(day.year, day.month, day.day);
          (temp[simpleDay] ??= []).add(booking);
        }

        setState(() {
          bookingsByDate = temp;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List<dynamic> _getBookingsForDay(DateTime day) {
    final simpleDay = DateTime(day.year, day.month, day.day);
    return bookingsByDate[simpleDay] ?? [];
  }

  Color _fillForDay(DateTime day) {
    final bookings = _getBookingsForDay(day);

    if (bookings.length >= totalSlots) {
      return Colors.red.shade400;
    }

    return Colors.transparent;
  }

  Widget _buildDayCell(
    DateTime day, {
    required Color fill,
    required Color border,
    Color? textColor,
    bool isSelected = false,
  }) {
    final numberColor = textColor ?? (fill != Colors.transparent ? Colors.white : Colors.black);

    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: border,
            width: border == Colors.transparent ? 0 : 2,
          ),
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: numberColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final lastDay = today.add(const Duration(days: 120));

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Colors.red.shade50,
        body: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TableCalendar(
                    locale: 'ar',
                    firstDay: today,
                    lastDay: lastDay,
                    focusedDay: focusedDay,
                    rowHeight: 52,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                    
                    onDaySelected: (selected, focused) async {
                      setState(() {
                        selectedDay = selected;
                        focusedDay = focused;
                      });

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FieldBookingSlotsPage(
                            field: widget.field,
                            date: selected,
                            bookings: _getBookingsForDay(selected),
                          ),
                        ),
                      );

                      await fetchBookings(); // refresh after returning
                    },
                    calendarStyle: const CalendarStyle(
                      cellPadding: EdgeInsets.zero,
                      cellMargin: EdgeInsets.zero,
                      todayDecoration: BoxDecoration(),
                      selectedDecoration: BoxDecoration(),
                    ),
                    calendarBuilders: CalendarBuilders(
                       headerTitleBuilder: (context, day) {
                                final text = MaterialLocalizations.of(context).formatMonthYear(day);
                                return Center(
                                  child: Text(
                                    AppFormat.toEnglishNumbers(text),
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
                          border: Colors.grey,
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
      ),
    );
  }
}
