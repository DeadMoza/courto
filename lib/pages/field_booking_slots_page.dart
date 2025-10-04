import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/auth_service.dart';

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
  final List<TimeSlot> _selectedSlots = [];

  static const double bookingPricePerHour = 10.0;
  String _bookingFrequency = 'daily';

  @override
  void initState() {
    super.initState();
    _generateSlots();
  }

  @override
  void didUpdateWidget(covariant FieldBookingSlotsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookings != oldWidget.bookings ||
        widget.field != oldWidget.field ||
        widget.date != oldWidget.date) {
      _generateSlots();
      _selectedSlots.clear();
    }
  }

  void _generateSlots() {
    final openParts = (widget.field['field_open_time'] ?? '08:00').split(':');
    final closeParts = (widget.field['field_close_time'] ?? '20:00').split(':');
    int openHour = int.parse(openParts[0]);
    int closeHour = int.parse(closeParts[0]);

    if (closeHour <= openHour) closeHour += 24;
    if (closeHour > 30) closeHour = 30;

    slots = [];
    for (int hour = openHour; hour < closeHour; hour++) {
      int normalizedHour = hour % 24;
      int normalizedEndHour = (hour + 1) % 24;

      DateTime start = DateTime(
          widget.date.year, widget.date.month, widget.date.day, normalizedHour);
      DateTime end = DateTime(
          widget.date.year, widget.date.month, widget.date.day, normalizedEndHour);

      if (hour >= 24) {
        start = start.add(const Duration(days: 1));
        end = end.add(const Duration(days: 1));
      }

      slots.add(TimeSlot(start: start, end: end));
    }
    setState(() {});
  }

  Map<String, dynamic>? _findBookingForSlot(TimeSlot slot) {
    try {
      return widget.bookings.firstWhere((b) {
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
      });
    } catch (e) {
      return null;
    }
  }

  bool _isConfirmed(TimeSlot slot) {
    final booking = _findBookingForSlot(slot);
    return booking?['booking_status'] == "confirmed" ||
        booking?['booking_status'] == "unavailable";
  }

  bool _isBooked(TimeSlot slot) {
  final booking = _findBookingForSlot(slot);
    return booking != null &&
      (booking['booking_status'] == "confirmed" ||
       booking['booking_status'] == "unavailable");

  } 

 void _onSlotTap(TimeSlot slot) {
  if (!AuthService.isLoggedIn) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SignupPage()));
    return;
  }

  if (_isBooked(slot)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('هذه الفترة محجوزة')),
    );
    return;
  }

  final alreadySelected =
      _selectedSlots.any((s) => s.start.isAtSameMomentAs(slot.start));

  if (alreadySelected) {
    // Only allow removing first or last slot
    final minTime =
        _selectedSlots.map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final maxTime =
        _selectedSlots.map((s) => s.start).reduce((a, b) => a.isAfter(b) ? a : b);

    if (slot.start.isAtSameMomentAs(minTime) ||
        slot.start.isAtSameMomentAs(maxTime)) {
      _selectedSlots.removeWhere((s) => s.start.isAtSameMomentAs(slot.start));
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'لا يمكنك إلغاء هذه الفترة لأنها جزء من سلسلة متتالية')),
      );
    }
    return;
  }

  if (_selectedSlots.isEmpty) {
    _selectedSlots.add(slot);
    setState(() {});
    return;
  }

  final minTime =
      _selectedSlots.map((s) => s.start).reduce((a, b) => a.isBefore(b) ? a : b);
  final maxTime =
      _selectedSlots.map((s) => s.start).reduce((a, b) => a.isAfter(b) ? a : b);

  final isAdjacent = slot.start.isAtSameMomentAs(minTime.subtract(const Duration(hours: 1))) ||
      slot.start.isAtSameMomentAs(maxTime.add(const Duration(hours: 1)));

  if (!isAdjacent) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('يجب اختيار فترات متتالية (حتى 3 ساعات فقط)')),
    );
    return;
  }

  if (_selectedSlots.length >= 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الحد الأقصى للاختيار 3 ساعات')),
    );
    return;
  }

  _selectedSlots.add(slot);
  _selectedSlots.sort((a, b) => a.start.compareTo(b.start));
  setState(() {});
}


  double get _fieldPricePerHour =>
      double.tryParse(widget.field['field_price'].toString()) ?? 0.0;

  double get _currentTotalBookingPrice =>
      _selectedSlots.length * bookingPricePerHour;

double get _remainingPaymentToOwner =>
    _selectedSlots.length * (_fieldPricePerHour - (bookingPricePerHour / 2));

// Replace your _onContinuePressed with this:
Future<void> _onContinuePressed() async {
  if (_selectedSlots.isEmpty) return;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "اختر نوع الحجز",
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Daily booking
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _bookingFrequency = "daily";
                      Navigator.pushNamed(
                        context,
                        '/confirmBooking',
                        arguments: {
                          'field': widget.field,
                          'date': widget.date.toIso8601String(),
                          'slots': _selectedSlots
                              .map((s) => {
                                    'start': s.start.toIso8601String(),
                                    'end': s.end.toIso8601String(),
                                  })
                              .toList(),
                          'total_price': _currentTotalBookingPrice,
                          'frequency': _bookingFrequency,
                        },
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("يومي"),
                      ],
                    ),
                  ),
                  // Monthly booking
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _bookingFrequency = "monthly";
                      Navigator.pushNamed(
                        context,
                        '/confirmBooking',
                        arguments: {
                          'field': widget.field,
                          'date': widget.date.toIso8601String(),
                          'slots': _selectedSlots
                              .map((s) => {
                                    'start': s.start.toIso8601String(),
                                    'end': s.end.toIso8601String(),
                                  })
                              .toList(),
                          'total_price': _currentTotalBookingPrice,
                          'frequency': _bookingFrequency,
                        },
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.calendar_view_month,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("شهري"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("إلغاء"),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          );
        },
      );
    },
  );
}

  Widget _buildSlotTile(TimeSlot slot) {
    final isConfirmed = _isConfirmed(slot);
    final isSelected =
        _selectedSlots.any((s) => s.start.isAtSameMomentAs(slot.start));

    Color bg;
    TextStyle textStyle;

    if (isConfirmed) {
      bg = Colors.redAccent;
      textStyle =
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    } else if (isSelected) {
      bg = Colors.blue.shade500;
      textStyle =
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold);
    } else {
      bg = Colors.white;
      textStyle =
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        onTap: () => _onSlotTap(slot),
        title: Center(
          child: Text(
            "${AppFormat.formatTime(slot.start)} - ${AppFormat.formatTime(slot.end)}",
            style: textStyle,
          ),
        ),
        subtitle: Center(
          child: isConfirmed
              ? const Text("محجوز", style: TextStyle(color: Colors.white))
              : (isSelected
                  ? Text(
                      "${_selectedSlots.indexWhere((s) => s.start.isAtSameMomentAs(slot.start)) + 1} / ${_selectedSlots.length}",
                      style: const TextStyle(color: Colors.white))
                  : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Colors.red.shade50,
        body: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: slots.length,
              itemBuilder: (context, i) => _buildSlotTile(slots[i]),
            ),
            if (_selectedSlots.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: SafeArea(
                  child: Material(
                            elevation: 4, // subtle shadow
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "سعر الحجز: ${_currentTotalBookingPrice.toStringAsFixed(2)} د.ل",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        "المتبقي بعد اللعب: ${_remainingPaymentToOwner.toStringAsFixed(2)} د.ل",
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: _onContinuePressed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5)),
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text('متابعة'),
                                  ),
                                ],
                              ),
                            ),
                          )

                ),
              ),
          ],
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
