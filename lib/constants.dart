import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui';

class AppFormat {
  // convert api time string into datetime to pass to formatting function (formatTime)
  static formatArabicTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      final dt = DateTime(0, 1, 1, hour, minute);
      return formatTime(dt);
    } catch (_) {
      return timeStr;
    }
  }

  // Arabic -> ص/م
  // English -> AM/PM
  static String formatTime(DateTime time) {
    try {
      final lang = Intl.getCurrentLocale(); // "ar" or "en"

      if (lang.startsWith("en")) {
        // English AM/PM format (e.g. 1:05 PM)
        return DateFormat("h:mm a", "en").format(time);
      }

      // Default Arabic format (ص/م)
      int hour = time.hour;
      String period = 'ص';
      if (hour >= 12) {
        period = 'م';
        if (hour > 12) hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }
      final minute = time.minute.toString().padLeft(2, '0');
      return "$hour:$minute $period";
    } catch (_) {
      // fallback to Arabic logic
      int hour = time.hour;
      String period = 'ص';
      if (hour >= 12) {
        period = 'م';
        if (hour > 12) hour -= 12;
      } else if (hour == 0) {
        hour = 12;
      }
      final minute = time.minute.toString().padLeft(2, '0');
      return "$hour:$minute $period";
    }
  }

  // تحويل التاريخ إلى صيغة عربية
  static String formatDateArabic(DateTime date) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  static String formatHM(DateTime dt) =>
      "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

  static String translateStatus(String status) {
    switch (status) {
      case "confirmed":
        return "مؤكد";
      case "pending":
        return "في انتظار الرد";
      case "cancelled":
        return "ملغي";
      default:
        return "غير متاح";
    }
  }

  static String toEnglishNumbers(String input) {
    const arabicNums = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const englishNums = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

    for (int i = 0; i < arabicNums.length; i++) {
      input = input.replaceAll(arabicNums[i], englishNums[i]);
    }
    return input;
  }
}

class FormationRepo {
  static final Map<int, List<Offset>> byCapacity = {
    // capacity: offsets for ONE team only (blue)
    2: [Offset(0.5, 0.5)], // 1v1: one player each
    4: [Offset(0.5, 0.75), Offset(0.5, 0.25)], // 2v2
    6: [Offset(0.5, 0.8), Offset(0.3, 0.5), Offset(0.7, 0.5)], // 3v3
    // ...
    22: _elevenV11(), // 11 players per team
  };

  static List<Offset> getTeamOffsets(int capacity) {
    final list = byCapacity[capacity];
    if (list != null) return list;

    // fallback: auto-generate a decent grid if missing
    return autoGenerate(teamSize: capacity ~/ 2);
  }

  static List<Offset> autoGenerate({required int teamSize}) {
    // simple vertical bands: GK + lines
    // not perfect, but prevents crashes
    final offsets = <Offset>[];
    if (teamSize <= 0) return offsets;

    // GK always first
    offsets.add(const Offset(0.5, 0.92));
    if (teamSize == 1) return offsets;

    // remaining players distributed in rows
    final remaining = teamSize - 1;
    final rows = (remaining / 4).ceil();
    int placed = 0;

    for (int r = 0; r < rows; r++) {
      final inRow = ((remaining - placed) >= 4) ? 4 : (remaining - placed);
      final y = 0.75 - (r * (0.55 / max(1, rows - 1))); // 0.75..0.20
      for (int c = 0; c < inRow; c++) {
        final x = (c + 1) / (inRow + 1); // evenly spaced
        offsets.add(Offset(x, y));
        placed++;
      }
    }
    return offsets;
  }

  static List<Offset> _elevenV11() {
    // Example 4-4-2 (with GK first)
    return const [
      Offset(0.5, 0.92), // GK

      // Back 4
      Offset(0.18, 0.78),
      Offset(0.38, 0.80),
      Offset(0.62, 0.80),
      Offset(0.82, 0.78),

      // Mid 4
      Offset(0.18, 0.56),
      Offset(0.38, 0.58),
      Offset(0.62, 0.58),
      Offset(0.82, 0.56),

      // Forwards 2
      Offset(0.40, 0.30),
      Offset(0.60, 0.30),
    ];
  }
}

