import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FieldBookingSlotsPage extends StatefulWidget {
  final Map<String, dynamic> field;
  final DateTime date;
  final List<dynamic> bookings;

  const FieldBookingSlotsPage({
    super.key,
    required this.field,
    required this.date,
    required this.bookings,
  });

  @override
  State<FieldBookingSlotsPage> createState() => _FieldBookingSlotsPageState();
}

class _FieldBookingSlotsPageState extends State<FieldBookingSlotsPage> {
  late List<TimeSlot> slots;

  @override
  void initState() {
    super.initState();
    _generateSlots();
  }

  @override
  void didUpdateWidget(covariant FieldBookingSlotsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookings != oldWidget.bookings) {
      _generateSlots();
    }
  }

  void _generateSlots() {
    final openParts = (widget.field['field_open_time'] ?? '08:00').split(':');
    final closeParts = (widget.field['field_close_time'] ?? '20:00').split(':');
    int openHour = int.parse(openParts[0]);
    int closeHour = int.parse(closeParts[0]);
    if (closeHour <= openHour) closeHour += 24;

    slots = [];
    for (int hour = openHour; hour < closeHour; hour++) {
      DateTime start = DateTime(widget.date.year, widget.date.month, widget.date.day, hour % 24);
      DateTime end = DateTime(widget.date.year, widget.date.month, widget.date.day, (hour + 1) % 24);
      if ((hour + 1) >= 24) end = end.add(const Duration(days: 1));
      slots.add(TimeSlot(start: start, end: end));
    }
    setState(() {});
  }

  Map<String, dynamic>? _findBookingForSlot(TimeSlot slot) {
    try {
      return widget.bookings.firstWhere(
        (b) {
          final bookingDate = DateTime.parse(b['booking_date']);
          final startParts = (b['start_time'] as String).split(':');
          final endParts = (b['end_time'] as String).split(':');

          final start = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            int.parse(startParts[0]),
            int.parse(startParts[1]),
          );
          final end = DateTime(
            bookingDate.year,
            bookingDate.month,
            bookingDate.day,
            int.parse(endParts[0]),
            int.parse(endParts[1]),
          );

          return slot.start.isAtSameMomentAs(start) ||
              (slot.start.isAfter(start) && slot.start.isBefore(end));
        },
      );
    } catch (e) {
      return null;
    }
  }


  bool _isConfirmed(TimeSlot slot) {
    final booking = _findBookingForSlot(slot);
    return booking?['booking_status'] == "confirmed";
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Colors.red.shade50,
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: slots.length,
          itemBuilder: (context, i) {
            final slot = slots[i];
            final isConfirmed = _isConfirmed(slot);

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isConfirmed ? Colors.redAccent : Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                title: Center(
                  child: Text(
                    "${AppFormat.formatTime(slot.start)} - ${AppFormat.formatTime(slot.end)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isConfirmed ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                subtitle: isConfirmed
                    ? const Center(
                        child: Text(
                          "محجوز",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : null,
  
              ),
            );
          },
        ),
      ),
    );
  }
}

class TimeSlot {
  final DateTime start;
  final DateTime end;
  TimeSlot({required this.start, required this.end});
}
