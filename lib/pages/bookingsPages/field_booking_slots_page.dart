import 'package:courto/app_bar.dart';
import 'package:courto/constants.dart';
import 'package:courto/pages/bookingsPages/daily_booking_confirmation_page.dart';
import 'package:courto/pages/bookingsPages/monthly_booking_confirmation_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../services/auth_service.dart';

class FieldBookingSlotsPage extends StatefulWidget {
  final Map<String, dynamic> field;
  final DateTime date;
  final List<dynamic> bookings;
  final List<dynamic> discountedSlots;

  const FieldBookingSlotsPage({
    super.key,
    required this.field,
    required this.date,
    required this.bookings,
    this.discountedSlots = const [],
  });

  @override
  State<FieldBookingSlotsPage> createState() => _FieldBookingSlotsPageState();
}

class _FieldBookingSlotsPageState extends State<FieldBookingSlotsPage> {
  late List<TimeSlot> slots;
  final List<TimeSlot> _selectedSlots = [];

  String _bookingFrequency = 'daily';

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  ui.TextDirection get _dir =>
      _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl;

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
        widget.date.year,
        widget.date.month,
        widget.date.day,
        normalizedHour,
      );
      DateTime end = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        normalizedEndHour,
      );

      if (hour >= 24) {
        start = start.add(const Duration(days: 1));
        end = end.add(const Duration(days: 1));
      }

      slots.add(TimeSlot(start: start, end: end));
    }
    if (mounted) setState(() {});
  }

  Map<String, dynamic>? _findBookingForSlot(TimeSlot slot) {
    try {
      return widget.bookings.firstWhere((b) {
        final bookingDate = DateTime.parse(b['booking_date']);
        final startParts = (b['start_time'] as String).split(':');
        final endParts = (b['end_time'] as String).split(':');

        int startHour = int.parse(startParts[0]);
        int endHour = int.parse(endParts[0]);

        var start = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          startHour,
          int.parse(startParts[1]),
        );
        var end = DateTime(
          bookingDate.year,
          bookingDate.month,
          bookingDate.day,
          endHour,
          int.parse(endParts[1]),
        );

        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 1));
        }

        final openHour = int.parse(
          (widget.field['field_open_time'] as String).split(':')[0],
        );

        if (openHour > startHour) {
          start = start.add(const Duration(days: 1));
          end = end.add(const Duration(days: 1));
        }

        return slot.start.isAtSameMomentAs(start) ||
            (slot.start.isAfter(start) && slot.start.isBefore(end));
      });
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _findDiscountForSlot(TimeSlot slot) {
    try {
      return widget.discountedSlots.firstWhere((ds) {
        final dsDate = DateTime.parse(ds['date']);

        final sParts = (ds['start_time'] as String).split(':');
        final eParts = (ds['end_time'] as String).split(':');

        int startHour = int.parse(sParts[0]);
        int endHour = int.parse(eParts[0]);

        var start = DateTime(
          dsDate.year,
          dsDate.month,
          dsDate.day,
          startHour,
          int.parse(sParts[1]),
        );

        var end = DateTime(
          dsDate.year,
          dsDate.month,
          dsDate.day,
          endHour,
          int.parse(eParts[1]),
        );

        if (end.isBefore(start)) {
          end = end.add(const Duration(days: 1));
        }

        final openHour = int.parse(
          (widget.field['field_open_time'] as String).split(':')[0],
        );

        if (openHour > startHour) {
          start = start.add(const Duration(days: 1));
          end = end.add(const Duration(days: 1));
        }

        return slot.start.isAtSameMomentAs(start) ||
            (slot.start.isAfter(start) && slot.start.isBefore(end));
      });
    } catch (_) {
      return null;
    }
  }

  // NEW: returns the discounted booking price only when the discount type
  // matches [frequency]. Falls back to the field's base price otherwise.
  double _effectiveBookingPrice(TimeSlot slot, String frequency) {
    final discount = _findDiscountForSlot(slot);
    if (discount == null) return _bookingPricePerHour;
    final appliesToFrequency = frequency == 'daily'
        ? discount['is_daily'] == true
        : discount['is_monthly'] == true;
    if (!appliesToFrequency) return _bookingPricePerHour;
    return double.tryParse(discount['booking_price'].toString()) ??
        _bookingPricePerHour;
  }

  // NEW: same logic for the remaining-to-owner price.
  double _effectiveRemainingPrice(TimeSlot slot, String frequency) {
    final discount = _findDiscountForSlot(slot);
    if (discount == null) return _remainingToOwnerPerHour ?? 0;
    final appliesToFrequency = frequency == 'daily'
        ? discount['is_daily'] == true
        : discount['is_monthly'] == true;
    if (!appliesToFrequency) return _remainingToOwnerPerHour ?? 0;
    return double.tryParse(discount['remaining_price'].toString()) ??
        (_remainingToOwnerPerHour ?? 0);
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupPage()),
      );
      return;
    }

    if (_isBooked(slot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? 'This time is booked' : 'هذه الفترة محجوزة',
            textDirection: _dir,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final alreadySelected =
        _selectedSlots.any((s) => s.start.isAtSameMomentAs(slot.start));

    if (alreadySelected) {
      final minTime = _selectedSlots
          .map((s) => s.start)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final maxTime = _selectedSlots
          .map((s) => s.start)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      if (slot.start.isAtSameMomentAs(minTime) ||
          slot.start.isAtSameMomentAs(maxTime)) {
        _selectedSlots.removeWhere((s) => s.start.isAtSameMomentAs(slot.start));
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish
                  ? "You can't remove this slot because it is part of a consecutive selection."
                  : 'لا يمكنك إلغاء هذه الفترة لأنها جزء من سلسلة متتالية',
              textDirection: _dir,
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    if (_selectedSlots.isEmpty) {
      _selectedSlots.add(slot);
      setState(() {});
      return;
    }

    final minTime = _selectedSlots
        .map((s) => s.start)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final maxTime = _selectedSlots
        .map((s) => s.start)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final isAdjacent =
        slot.start.isAtSameMomentAs(minTime.subtract(const Duration(hours: 1))) ||
            slot.start.isAtSameMomentAs(maxTime.add(const Duration(hours: 1)));

    if (!isAdjacent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Select consecutive slots (up to 3 hours)'
                : 'يجب اختيار فترات متتالية (حتى 3 ساعات فقط)',
            textDirection: _dir,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedSlots.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish ? 'Max selection is 3 hours' : 'الحد الأقصى للاختيار 3 ساعات',
            textDirection: _dir,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    _selectedSlots.add(slot);
    _selectedSlots.sort((a, b) => a.start.compareTo(b.start));
    setState(() {});
  }

  double get _bookingPricePerHour =>
      double.tryParse(widget.field['field_calculated_booking_price'].toString()) ??
      0.0;

  double? get _remainingToOwnerPerHour => widget.field["field_has_discount"] == true
      ? double.tryParse(
          widget.field["field_calculated_remaining_price_after_discount"].toString(),
        )
      : double.tryParse(widget.field['field_calculated_remaining_price'].toString());

  // Uses _effectiveBookingPrice so the correct price is applied per frequency
  // when the value is read inside the dialog's onTap (after _bookingFrequency is set).
  double get _currentTotalBookingPrice =>
      _selectedSlots.fold(0.0, (sum, slot) =>
          sum + _effectiveBookingPrice(slot, _bookingFrequency));

  // Same for remaining price.
  double get _remainingPaymentToOwner =>
      _selectedSlots.fold(0.0, (sum, slot) =>
          sum + _effectiveRemainingPrice(slot, _bookingFrequency));

  Future<void> _onContinuePressed() async {
    if (_selectedSlots.isEmpty) return;

    _selectedSlots.sort((a, b) => a.start.compareTo(b.start));

    final firstSlot = _selectedSlots.first;
    final lastSlot = _selectedSlots.last;
    final baseDate = widget.date;

    final normalizedStart = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      firstSlot.start.hour,
    );
    final normalizedEnd = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      lastSlot.end.hour,
    );

    final mergedSlot = [
      {
        'start': normalizedStart.toIso8601String(),
        'end': normalizedEnd.toIso8601String(),
      }
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: _dir,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Text(
              _isEnglish ? "Choose booking type" : "اختر نوع الحجز",
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
                      // _currentTotalBookingPrice and _remainingPaymentToOwner
                      // are read here, after _bookingFrequency = "daily",
                      // so only is_daily discounts are applied.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DailyBookingConfirmationPage(
                            field: widget.field,
                            date: widget.date,
                            slots: mergedSlot,
                            totalBookingPrice: _currentTotalBookingPrice,
                            remainingPaymentToOwner: _remainingPaymentToOwner,
                            frequency: _bookingFrequency,
                            userId: AuthService.userData?['id'],
                          ),
                        ),
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
                          child: const Icon(Icons.calendar_today,
                              size: 40, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(_isEnglish ? "Daily" : "يومي"),
                      ],
                    ),
                  ),

                  // Monthly booking
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _bookingFrequency = "monthly";
                      // _currentTotalBookingPrice and _remainingPaymentToOwner
                      // are read here, after _bookingFrequency = "monthly",
                      // so only is_monthly discounts are applied.
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MonthlyBookingConfirmationPage(
                            field: widget.field,
                            date: widget.date,
                            slots: mergedSlot,
                            totalBookingPrice: _currentTotalBookingPrice,
                            remainingPaymentToOwner: _remainingPaymentToOwner,
                            frequency: _bookingFrequency,
                            userId: AuthService.userData?['id'],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.calendar_view_month,
                              size: 40, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        Text(_isEnglish ? "Monthly" : "شهري"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(_isEnglish ? "Cancel" : "إلغاء"),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
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
      bg = Theme.of(context).colorScheme.primary;
      textStyle = TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      );
    } else if (isSelected) {
      bg = Colors.amber;
      textStyle = TextStyle(
        color: Theme.of(context).colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      );
    } else {
      bg = Theme.of(context).colorScheme.onPrimary;
      textStyle = TextStyle(
        color: Theme.of(context).colorScheme.onSecondary,
        fontWeight: FontWeight.bold,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Theme.of(context).colorScheme.onPrimary),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        onTap: () => _onSlotTap(slot),
        title: Center(
          child: Text(
            "${AppFormat.formatTime(slot.start)} - ${AppFormat.formatTime(slot.end)}",
            style: textStyle,
            textDirection: _dir,
          ),
        ),
        subtitle: Center(
          child: isConfirmed
              ? Text(
                  _isEnglish ? "Booked" : "محجوز",
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  textDirection: _dir,
                )
              : (isSelected
                  ? Text(
                      "${_selectedSlots.indexWhere((s) => s.start.isAtSameMomentAs(slot.start)) + 1} / ${_selectedSlots.length}",
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      textDirection: _dir,
                    )
                  : _buildDiscountSubtitle(slot)),
        ),
      ),
    );
  }

  Widget? _buildDiscountSubtitle(TimeSlot slot) {
    final discount = _findDiscountForSlot(slot);
    if (discount == null) return null;

    final discountedBooking =
        double.tryParse(discount['booking_price'].toString()) ?? 0.0;
    final discountedRemaining =
        double.tryParse(discount['remaining_price'].toString()) ?? 0.0;
    final isDaily = discount['is_daily'] == true;
    final isMonthly = discount['is_monthly'] == true;

    final String typeLabel;
    if (isDaily && isMonthly) {
      typeLabel = _isEnglish ? 'Daily & Monthly' : 'يومي وشهري';
    } else if (isMonthly) {
      typeLabel = _isEnglish ? 'Monthly' : 'تخفيض شهري';
    } else {
      typeLabel = _isEnglish ? 'Daily' : 'تخفيض يومي';
    }

    final currency = _isEnglish ? 'LYD' : 'د.ل';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_bookingPricePerHour.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSecondary
                      .withOpacity(0.5),
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Theme.of(context)
                      .colorScheme
                      .onSecondary
                      .withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${discountedBooking.toStringAsFixed(2)} $currency',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEnglish
                    ? 'Remaining: ${discountedRemaining.toStringAsFixed(2)} $currency'
                    : 'المتبقي: ${discountedRemaining.toStringAsFixed(2)} $currency',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSecondary
                      .withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: Colors.amber.shade600, width: 0.8),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onPrimary,
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
                                _isEnglish
                                    ? "Booking price: ${_currentTotalBookingPrice.toStringAsFixed(2)} LYD"
                                    : "سعر الحجز: ${_currentTotalBookingPrice.toStringAsFixed(2)} د.ل",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textDirection: _dir,
                              ),
                              Text(
                                _isEnglish
                                    ? "Remaining after play: ${_remainingPaymentToOwner.toStringAsFixed(2)} LYD"
                                    : "المتبقي بعد اللعب: ${_remainingPaymentToOwner.toStringAsFixed(2)} د.ل",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                                textDirection: _dir,
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: _onContinuePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(_isEnglish ? 'Continue' : 'متابعة'),
                          ),
                        ],
                      ),
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

class TimeSlot {
  final DateTime start;
  final DateTime end;
  TimeSlot({required this.start, required this.end});
}