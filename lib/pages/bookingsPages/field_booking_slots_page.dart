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

  /// Standing admin rules that take a time range off this field's calendar on
  /// every day. Each carries a display_mode: 'hidden' drops the slot from the
  /// grid, 'booked' leaves it drawn but unbookable.
  final List<dynamic> hiddenSlots;

  const FieldBookingSlotsPage({
    super.key,
    required this.field,
    required this.date,
    required this.bookings,
    this.discountedSlots = const [],
    this.hiddenSlots = const [],
  });

  @override
  State<FieldBookingSlotsPage> createState() => _FieldBookingSlotsPageState();
}

class _FieldBookingSlotsPageState extends State<FieldBookingSlotsPage> {
  late List<TimeSlot> slots;
  final List<TimeSlot> _selectedSlots = [];

  // How many slots one booking may span. This is a slot count, not an hour
  // count: on a 15-minute field 3 slots is 45 minutes.
  static const int _maxSlotsPerSelection = 3;

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

  // "HH:mm[:ss]" -> minutes since midnight. Null when unparseable.
  int? _parseMinutes(dynamic raw) {
    if (raw == null) return null;
    final parts = raw.toString().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  // The field's slot size in minutes: 15, 30 or 60. Anything else (missing
  // column, older API) falls back to the 1-hour grid this page used to assume.
  int get _slotDuration {
    final raw = int.tryParse(
      widget.field['field_slot_duration']?.toString() ?? '',
    );
    return (raw == 15 || raw == 30 || raw == 60) ? raw! : 60;
  }

  // How many bookings this field can run at once in a single slot. 1 is the
  // old behaviour, where the first booking closed the slot for everyone; a
  // karting track with 6 carts sells the same 09:15 slot 6 times.
  int get _slotSeats {
    final raw = int.tryParse(
      widget.field['field_slot_seats']?.toString() ?? '',
    );
    return (raw != null && raw >= 1) ? raw : 1;
  }

  bool get _isMultiSeat => _slotSeats > 1;

  // Wall-clock time on the booking day; minutes past 24h roll into the next
  // day, which is what an after-midnight slot needs.
  DateTime _slotTime(int minutesFromMidnight) => DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        0,
        minutesFromMidnight,
      );

  // The pieces a daily-repeating window occupies inside one day. A window
  // whose end is at or before its start has run past midnight, so it comes
  // back as two pieces; end == start means the whole day.
  List<List<int>> _dailyPieces(int startMin, int endMin) {
    final a = startMin % (24 * 60);
    final b = endMin % (24 * 60);
    if (b > a) return [[a, b]];
    if (b == a) return [[0, 24 * 60]];
    return [[a, 24 * 60], [0, b]];
  }

  /// The standing rule covering [slot], if any. Half-open, so a slot ending
  /// exactly when a rule starts is untouched.
  Map<String, dynamic>? _hiddenRuleForSlot(TimeSlot slot) {
    final slotStart = slot.start.hour * 60 + slot.start.minute;
    var slotEnd = slot.end.hour * 60 + slot.end.minute;
    if (slotEnd <= slotStart) slotEnd += 24 * 60;
    final slotPieces = _dailyPieces(slotStart, slotEnd);

    for (final h in widget.hiddenSlots) {
      final hs = _parseMinutes(h['start_time']);
      final he = _parseMinutes(h['end_time']);
      if (hs == null || he == null) continue;

      final rulePieces = _dailyPieces(hs, he);
      final overlaps = slotPieces.any(
        (sp) => rulePieces.any((rp) => sp[0] < rp[1] && rp[0] < sp[1]),
      );
      if (overlaps) return h as Map<String, dynamic>;
    }
    return null;
  }

  void _generateSlots() {
    final openMinutes = _parseMinutes(widget.field['field_open_time']) ?? 8 * 60;
    int closeMinutes =
        _parseMinutes(widget.field['field_close_time']) ?? 20 * 60;

    if (closeMinutes <= openMinutes) closeMinutes += 24 * 60;
    if (closeMinutes > 30 * 60) closeMinutes = 30 * 60;

    final step = _slotDuration;

    slots = [];
    for (int m = openMinutes; m + step <= closeMinutes; m += step) {
      final slot = TimeSlot(start: _slotTime(m), end: _slotTime(m + step));

      // A rule in 'hidden' mode drops the slot from the day entirely; one in
      // 'booked' mode keeps it drawn, and _isBooked below makes it untappable.
      final rule = _hiddenRuleForSlot(slot);
      if (rule != null && rule['display_mode'] != 'booked') continue;

      slots.add(slot);
    }
    if (mounted) setState(() {});
  }

  // True when [slot] starts inside the [start, end) range a booking or a
  // discount covers. Testing the slot START (rather than an exact time match)
  // is what lets one 60-minute booking mark all four slots of a 15-minute grid
  // as taken - which is exactly what happens after a field changes its grid.
  bool _rangeCoversSlot(
    TimeSlot slot,
    DateTime rangeDate,
    dynamic rawStart,
    dynamic rawEnd,
  ) {
    final startMinutes = _parseMinutes(rawStart);
    final endMinutes = _parseMinutes(rawEnd);
    if (startMinutes == null || endMinutes == null) return false;

    // A range stored under this date but starting before the field opens ran
    // past midnight, so it belongs to the following calendar day.
    final openMinutes = _parseMinutes(widget.field['field_open_time']) ?? 0;
    final dayShift = startMinutes < openMinutes ? 1 : 0;

    var start = DateTime(
      rangeDate.year,
      rangeDate.month,
      rangeDate.day + dayShift,
      0,
      startMinutes,
    );
    var end = DateTime(
      rangeDate.year,
      rangeDate.month,
      rangeDate.day + dayShift,
      0,
      endMinutes,
    );

    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    return slot.start.isAtSameMomentAs(start) ||
        (slot.start.isAfter(start) && slot.start.isBefore(end));
  }

  // Every booking overlapping [slot]. On a 1-seat field this is at most one
  // row; on a multi-seat field it is however many carts are already out.
  List<Map<String, dynamic>> _bookingsForSlot(TimeSlot slot) {
    final found = <Map<String, dynamic>>[];
    for (final b in widget.bookings) {
      try {
        if (_rangeCoversSlot(
          slot,
          DateTime.parse(b['booking_date']),
          b['start_time'],
          b['end_time'],
        )) {
          found.add(b as Map<String, dynamic>);
        }
      } catch (_) {}
    }
    return found;
  }

  // Seats already gone. A slot the owner closed can hold several seats in one
  // booking row, so seats are summed rather than counted.
  int _occupiedSeats(TimeSlot slot) {
    var taken = 0;
    for (final b in _bookingsForSlot(slot)) {
      final status = b['booking_status'];
      if (status != 'confirmed' && status != 'unavailable') continue;
      taken += int.tryParse(b['booking_seats']?.toString() ?? '') ?? 1;
    }
    return taken;
  }

  int _seatsLeft(TimeSlot slot) {
    final left = _slotSeats - _occupiedSeats(slot);
    return left < 0 ? 0 : left;
  }

  Map<String, dynamic>? _findDiscountForSlot(TimeSlot slot) {
    try {
      return widget.discountedSlots.firstWhere(
        (ds) => _rangeCoversSlot(
          slot,
          DateTime.parse(ds['date']),
          ds['start_time'],
          ds['end_time'],
        ),
      );
    } catch (_) {
      return null;
    }
  }

  // NEW: returns the discounted booking price only when the discount type
  // matches [frequency]. Falls back to the field's base price otherwise.
  double _effectiveBookingPrice(TimeSlot slot, String frequency) {
    final discount = _findDiscountForSlot(slot);
    if (discount == null) return _bookingPricePerSlot;
    final appliesToFrequency = frequency == 'daily'
        ? discount['is_daily'] == true
        : discount['is_monthly'] == true;
    if (!appliesToFrequency) return _bookingPricePerSlot;
    return double.tryParse(discount['booking_price'].toString()) ??
        _bookingPricePerSlot;
  }

  // NEW: same logic for the remaining-to-owner price.
  double _effectiveRemainingPrice(TimeSlot slot, String frequency) {
    final discount = _findDiscountForSlot(slot);
    if (discount == null) return _remainingToOwnerPerSlot ?? 0;
    final appliesToFrequency = frequency == 'daily'
        ? discount['is_daily'] == true
        : discount['is_monthly'] == true;
    if (!appliesToFrequency) return _remainingToOwnerPerSlot ?? 0;
    return double.tryParse(discount['remaining_price'].toString()) ??
        (_remainingToOwnerPerSlot ?? 0);
  }

  // Taken means every seat is gone, not just that someone booked. On a 1-seat
  // field one booking still fills it, so nothing changes for a pitch. A slot
  // an admin took off the calendar is never for sale either; the only ones
  // that reach here are 'booked'-mode rules, since 'hidden' ones are not drawn.
  bool _isBooked(TimeSlot slot) =>
      _hiddenRuleForSlot(slot) != null || _seatsLeft(slot) <= 0;

  bool _isConfirmed(TimeSlot slot) => _isBooked(slot);

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
            // A slot taken off the calendar is not "sold out", so the seat
            // wording would be a lie about why it cannot be booked.
            (_isMultiSeat && _hiddenRuleForSlot(slot) == null)
                ? (_isEnglish
                    ? 'All $_slotSeats places for this time are taken'
                    : 'كل الأماكن ($_slotSeats) في هذه الفترة محجوزة')
                : (_isEnglish ? 'This time is booked' : 'هذه الفترة محجوزة'),
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

    final step = Duration(minutes: _slotDuration);
    final isAdjacent = slot.start.isAtSameMomentAs(minTime.subtract(step)) ||
        slot.start.isAtSameMomentAs(maxTime.add(step));

    if (!isAdjacent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Select consecutive slots (up to $_maxSlotsPerSelection slots)'
                : 'يجب اختيار فترات متتالية (حتى $_maxSlotsPerSelection فترات فقط)',
            textDirection: _dir,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedSlots.length >= _maxSlotsPerSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEnglish
                ? 'Max selection is $_maxSlotsPerSelection slots'
                : 'الحد الأقصى للاختيار $_maxSlotsPerSelection فترات',
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

  // Prices are PER SLOT, not per hour: a field priced at 50 charges 50 for one
  // slot whether that slot is 15, 30 or 60 minutes. Nothing here prorates.
  double get _bookingPricePerSlot =>
      double.tryParse(widget.field['field_calculated_booking_price'].toString()) ??
      0.0;

  double? get _remainingToOwnerPerSlot => widget.field["field_has_discount"] == true
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

    // Pinned back onto the selected day: the API stores a booking under the day
    // the session STARTED plus a bare start/end time, so an after-midnight slot
    // must not carry its +1 day. Minutes are kept - dropping them collapsed
    // every 20:30 slot into 20:00.
    final normalizedStart = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      firstSlot.start.hour,
      firstSlot.start.minute,
    );
    final normalizedEnd = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      lastSlot.end.hour,
      lastSlot.end.minute,
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
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_buildDiscountSubtitle(slot) case final d?) d,
                        // Seat counts are meaningless on a slot that is off
                        // the calendar, so they are suppressed there.
                        if (_isMultiSeat && _hiddenRuleForSlot(slot) == null)
                          _buildSeatsSubtitle(slot),
                      ],
                    )),
        ),
      ),
    );
  }

  // Only shown on fields that run several bookings at once, where "free" is
  // not the whole story: 2 of 6 carts left reads very differently from 6.
  Widget _buildSeatsSubtitle(TimeSlot slot) {
    final left = _seatsLeft(slot);
    final label = _isEnglish
        ? '$left of $_slotSeats available'
        : 'متبقي $left من $_slotSeats';

    // Running low gets a warmer colour so it reads as urgency, not decoration.
    final isLow = left <= (_slotSeats / 3).ceil();
    final color = isLow ? Colors.deepOrange : Colors.teal;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          textDirection: _dir,
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
                '${_bookingPricePerSlot.toStringAsFixed(2)} $currency',
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