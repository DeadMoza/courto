// lib/pages/matchmakingPages/create_match_page.dart
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:courto/l10n/app_localizations.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../constants.dart'; // AppFormat + FormationRepo

class CreateMatchPage extends StatefulWidget {
  /// City the user is currently browsing, used as the default when they post
  /// a match with no booking behind it.
  final int? initialCityId;

  const CreateMatchPage({super.key, this.initialCityId});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final apiUrl = dotenv.env['API_URL'];

  bool _loading = true;
  bool _creating = false;
  String? _error;

  List<Map<String, dynamic>> _eligibleBookings = [];
  int _selectedIndex = 0;

  int _openSlots = 1; // ✅ never allow 0
  int? _selectedBluePosition; // 1..teamSize

  // ---- "find players first" mode -------------------------------------------
  // No booking behind the match: the host says where and when they WANT to
  // play, and books the pitch later once enough people have joined.
  bool _openMode = false;

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _fieldTypes = [];
  List<Map<String, dynamic>> _cityFields = [];
  bool _loadingCityFields = false;

  int? _cityId;
  int? _fieldTypeId;
  int? _preferredFieldId; // a venue the host likes, NOT a reservation
  DateTime? _matchDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _openTotalSlots = 10;
  final TextEditingController _notesController = TextEditingController();

  Map<String, dynamic>? get _selectedBooking =>
      _eligibleBookings.isEmpty ? null : _eligibleBookings[_selectedIndex];

  Map<String, dynamic>? get _preferredField {
    if (_preferredFieldId == null) return null;
    for (final f in _cityFields) {
      if (int.tryParse(f['field_id']?.toString() ?? '') == _preferredFieldId) {
        return f;
      }
    }
    return null;
  }

  /// Players the game needs. With a booking that is the field's capacity;
  /// without one there is no field to ask, so the host states it.
  int get _capacity {
    if (_openMode) return _openTotalSlots;
    final b = _selectedBooking;
    if (b == null) return 0;
    final c = b['field_capacity'] ?? b['capacity'] ?? b['total_slots'];
    return int.tryParse(c?.toString() ?? '') ?? 0;
  }

  int get _teamSize => (_capacity > 0) ? (_capacity ~/ 2) : 0;

  bool get _isEnglish {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    return code.startsWith('en');
  }

  // -------- field type: from the booking, or from what the host picked -----
  String get _fieldTypeRaw {
    if (_openMode) {
      final f = _preferredField;
      if (f != null) return (f['field_type'] ?? '').toString().toLowerCase();
      for (final t in _fieldTypes) {
        if (int.tryParse(t['field_type_id']?.toString() ?? '') == _fieldTypeId) {
          return (t['field_type'] ?? '').toString().toLowerCase();
        }
      }
      return '';
    }
    final b = _selectedBooking;
    if (b == null) return '';
    return (b['field_type']).toString().toLowerCase();
  }

  String get _fieldKind {
    final t = _fieldTypeRaw;
    if (t.contains("football") || t.contains("soccer")) return "football";
    if (t.contains("padel")) return "padel";
    if (t.contains("tennis")) return "tennis";
    if (t.contains("basketball")) return "basketball";
    return "other";
  }

  IconData get _fieldIcon {
    switch (_fieldKind) {
      case "football":
        return Icons.sports_soccer;
      case "padel":
      case "tennis":
        return Icons.sports_tennis;
      case "basketball":
        return Icons.sports_basketball;
      default:
        return Icons.sports;
    }
  }

  String get _fieldLabel {
    final loc = AppLocalizations.of(context)!;
    switch (_fieldKind) {
      case "football":
        return loc.fieldTypeFootball;
      case "padel":
        return loc.fieldTypePadel;
      case "tennis":
        return loc.fieldTypeTennis;
      case "basketball":
        return loc.fieldTypeBasketball;
      default:
        return loc.fieldTypeSport;
    }
  }

  void _showRedSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _cityId = widget.initialCityId;
    _fetchEligibleBookings();
    _fetchOpenMatchOptions();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Cities and sports for the "no booking" form. Failures are quiet: the
  // booking-backed path does not need any of this.
  Future<void> _fetchOpenMatchOptions() async {
    try {
      final results = await Future.wait([
        http.get(
          Uri.parse('${apiUrl}users/getCities'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
        ),
        http.get(
          Uri.parse('${apiUrl}users/getFieldTypes'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
        ),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200) {
        _cities = List<Map<String, dynamic>>.from(jsonDecode(results[0].body));
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body);
        _fieldTypes = List<Map<String, dynamic>>.from(data['data'] ?? []);
      }

      // Default to the first sport so the form is usable straight away.
      _fieldTypeId ??= _fieldTypes.isEmpty
          ? null
          : int.tryParse(_fieldTypes.first['field_type_id']?.toString() ?? '');

      setState(() {});
      if (_cityId != null) await _fetchCityFields();
    } catch (_) {
      // leave the lists empty; the form validates before submitting
    }
  }

  // Fields in the chosen city, offered as an optional "I'd like to play here".
  Future<void> _fetchCityFields() async {
    if (_cityId == null) return;
    setState(() {
      _loadingCityFields = true;
      _cityFields = [];
      _preferredFieldId = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${apiUrl}users/getFieldsByCity/$_cityId'),
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cityFields = List<Map<String, dynamic>>.from(data['fields'] ?? []);
      }
    } catch (_) {
      _cityFields = [];
    } finally {
      if (mounted) setState(() => _loadingCityFields = false);
    }
  }

  // Fields matching the chosen sport, since a padel court is no use to
  // someone organising football.
  List<Map<String, dynamic>> get _matchingCityFields {
    if (_fieldTypeId == null) return _cityFields;
    String typeName = '';
    for (final t in _fieldTypes) {
      if (int.tryParse(t['field_type_id']?.toString() ?? '') == _fieldTypeId) {
        typeName = (t['field_type'] ?? '').toString().toLowerCase();
      }
    }
    if (typeName.isEmpty) return _cityFields;
    return _cityFields
        .where((f) => (f['field_type'] ?? '').toString().toLowerCase() == typeName)
        .toList();
  }

  // City name map (Arabic -> English)
  static const Map<String, String> _cityEnMap = {
    "طرابلس": "Tripoli",
    "مصراتة": "Misrata",
    "بنغازي": "Benghazi",
    "الزاوية": "Zawiya",
    "الخمس": "Khoms",
    "سرت": "Surt",
    "درنة": "Derna",
    "طبرق": "Tobruk",
    "سبها": "Sabha",
    "صبراتة": "Subrata",
    "زوارة": "Zuwara",
  };

  static const Map<String, String> _locationEnMap = {
    "الظهرة": "Al Dahra",
    "زاوية الدهماني": "Zawiyat Al Dahmani",
    "أبو سليم": "Abu Salim",
    "الحي الإسلامي": "Al Islamic District",
    "الدريبي": "Al Draybi",
    "السراج": "Al Sarraj",
    "المدينة القديمة": "Old City",
    "الهاني": "Al Hani",
    "الهضبة الخضراء": "Green Plateau",
    "باب بن غشير": "Bab Ben Ghashir",
    "حي الأندلس": "Hay Al Andalus",
    "حي دمشق": "Hay Dimashq",
    "رأس حسن": "Ras Hassan",
    "زناتة": "Zanata",
    "سوق الجمعة": "Souq Al Jomaa",
    "غوط الشعال": "Ghout Al Shaal",
    "المنصورة": "Al Mansoura",
    "وسعاية أبديري": "Wesaaeya Abdeeri",
    "الصريم": "Al Srim",
    "بن عاشور": "Bin Ashour",
    "جنزور": "Janzour",
    "تاجوراء": "Tajoura",
    "المدينة": "Al Madina",
  };

  String _translateCityIfNeeded(String cityArOrAny) {
    if (!_isEnglish) return cityArOrAny;
    return _cityEnMap[cityArOrAny] ?? cityArOrAny;
  }

  String _translateLocationIfNeeded(String locArOrAny) {
    if (!_isEnglish) return locArOrAny;
    return _locationEnMap[locArOrAny] ?? locArOrAny;
  }

  Future<void> _fetchEligibleBookings() async {
    setState(() {
      _loading = true;
      _error = null;
      _eligibleBookings = [];
      _selectedBluePosition = null;
      _openSlots = 1; // ✅
    });

    final userId = AuthService.userData?['id'];
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.createMatchLoginRequired;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse('${apiUrl}users/getEligibleMatchBookings/$userId'),
        headers: {
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rows = List<Map<String, dynamic>>.from(data['data'] ?? []);

        setState(() {
          _eligibleBookings = rows;
          _selectedIndex = 0;

          final cap = _capacity;
          _openSlots = cap > 0 ? max(1, cap ~/ 2) : 1; // ✅ never 0

          _selectedBluePosition = (_teamSize > 0) ? 1 : null; // default host position
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.createMatchLoadEligibleBookingsFailed;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.createMatchConnectionError;
      });
    }
  }

  void _selectBooking(int i) {
    setState(() {
      _selectedIndex = i;

      final cap = _capacity;
      _openSlots = cap > 0 ? max(1, cap ~/ 2) : 1; // ✅ never 0

      _selectedBluePosition = (_teamSize > 0) ? 1 : null;
    });
  }

  // ✅ English months in EN, Arabic months in AR
  String _formatBookingDate(dynamic bookingDate) {
    try {
      final dt = DateTime.parse(bookingDate.toString());
      if (_isEnglish) return DateFormat('d MMM y', 'en').format(dt); // e.g. 16 Feb 2026
      return AppFormat.formatDateArabic(dt); // Arabic months
    } catch (_) {
      return bookingDate?.toString() ?? '';
    }
  }

  String _formatApiTime(dynamic time) {
    if (time == null) return '';
    return AppFormat.formatArabicTime(time.toString()); // AM/PM in EN, ص/م in AR
  }

  // ---------------- Formation Preview (simple dots) ----------------
  Widget _formationPreview({required int capacity, required int openSlots}) {
    final loc = AppLocalizations.of(context)!;

    if (capacity <= 0) {
      return SizedBox(
        height: 110,
        child: Center(child: Text(loc.createMatchNoCapacityFormation)),
      );
    }

    final leftCount = capacity ~/ 2;
    final rightCount = capacity - leftCount;

    final openLeft = (openSlots / 2).ceil().clamp(0, leftCount);
    final openRight = (openSlots - openLeft).clamp(0, rightCount);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _teamDots(
                  count: leftCount,
                  openCount: openLeft,
                  color: Colors.blue,
                  label: Text(loc.blueTeam, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _teamDots(
                  count: rightCount,
                  openCount: openRight,
                  color: Colors.red,
                  label: Text(loc.redTeam, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.createMatchAvailableToJoin(openSlots, capacity),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamDots({
    required int count,
    required int openCount,
    required Color color,
    required Widget label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label,
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(count, (i) {
            final isOpen = i < openCount;
            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? color : Colors.transparent,
                border: Border.all(
                  color: isOpen ? color : Colors.grey.withOpacity(0.6),
                  width: 2,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------- ✅ BLUE POSITION PICKER CANVAS (more compact) ----------------
  Widget _positionPickerBlue({required int capacity}) {
    final loc = AppLocalizations.of(context)!;

    if (capacity <= 0) {
      return SizedBox(
        height: 140,
        child: Center(child: Text(loc.createMatchNoCapacityPositions)),
      );
    }

    final teamSize = capacity ~/ 2;
    if (teamSize <= 0) {
      return SizedBox(
        height: 140,
        child: Center(child: Text(loc.createMatchNoPositions)),
      );
    }

    final offsets = FormationRepo.getTeamOffsets(capacity);

    final safeOffsets = offsets.length >= teamSize
        ? offsets.take(teamSize).toList()
        : FormationRepo.autoGenerate(teamSize: teamSize);

    final finalOffsets = safeOffsets.length >= teamSize
        ? safeOffsets.take(teamSize).toList()
        : List<Offset>.generate(teamSize, (i) {
            final y = 0.85 - (i * (0.70 / max(1, teamSize - 1)));
            return Offset(0.5, y);
          });

    _selectedBluePosition ??= 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10), // ✅ tighter
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header with field type icon + label
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.createMatchChooseYourPositionBlue,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_fieldIcon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  _fieldLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ more compact canvas
            AspectRatio(
              aspectRatio: 16 / 14,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.25),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;
                    final h = c.maxHeight;
                    const pad = 8.0; // ✅ tighter

                    Offset toCanvas(Offset o) {
                      final x = pad + o.dx * (w - pad * 2);
                      final y = pad + o.dy * (h - pad * 2);
                      return Offset(x, y);
                    }

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FieldKindPainter(kind: _fieldKind),
                          ),
                        ),

                        // dots
                        ...List.generate(teamSize, (i) {
                          final position = i + 1; // ✅ STATIC INDEX
                          final center = toCanvas(finalOffsets[i]);
                          final isSelected = _selectedBluePosition == position;

                          return Positioned(
                            left: center.dx - 14, // ✅ smaller
                            top: center.dy - 14,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setState(() => _selectedBluePosition = position),
                              child: Container(
                                width: 28, // ✅ smaller
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: isSelected ? 2.4 : 2.0,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    "$position",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: isSelected ? Colors.white : Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              loc.createMatchSelectedPosition("${_selectedBluePosition ?? "-"}"),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------- CREATE MATCH WITH NO BOOKING ----------------
  Future<void> _onCreateOpenPressed() async {
    final loc = AppLocalizations.of(context)!;
    final userId = AuthService.userData?['id'];
    if (userId == null) return;

    if (_cityId == null) {
      _showRedSnack(loc.createMatchPickCity);
      return;
    }

    if (_matchDate == null || _startTime == null || _endTime == null) {
      _showRedSnack(loc.createMatchPickDateTime);
      return;
    }

    final start = DateTime(
      _matchDate!.year, _matchDate!.month, _matchDate!.day,
      _startTime!.hour, _startTime!.minute,
    );
    var end = DateTime(
      _matchDate!.year, _matchDate!.month, _matchDate!.day,
      _endTime!.hour, _endTime!.minute,
    );
    // An end at or before the start means the game runs past midnight.
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));

    // Mirrors the server's 6-hour floor so the user is told before the round
    // trip rather than after it.
    if (start.isBefore(DateTime.now().add(const Duration(hours: 6)))) {
      _showRedSnack(loc.createMatchStartsTooSoon);
      return;
    }

    final hostPos = _selectedBluePosition;
    final teamSize = _teamSize;
    if (teamSize <= 0 || hostPos == null || hostPos < 1 || hostPos > teamSize) {
      _showRedSnack(loc.createMatchPickValidPositionFirst);
      return;
    }

    final openSlots = _openSlots.clamp(1, max(1, _openTotalSlots - 1));

    setState(() => _creating = true);

    try {
      final res = await http.post(
        Uri.parse('${apiUrl}users/createOpenMatch'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({
          'city_id': _cityId,
          'field_type_id': _fieldTypeId,
          'field_id': _preferredFieldId,
          'match_date': _fmtDate(_matchDate!),
          'start_time': _fmtTime(_startTime!),
          'end_time': _fmtTime(_endTime!),
          'total_slots': _openTotalSlots,
          'open_slots': openSlots,
          'position': hostPos,
          'notes': _notesController.text.trim(),
        }),
      );

      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showRedSnack(decoded?['message'] ?? loc.createMatchCreatedSuccess);
        Navigator.pop(context, true);
        return;
      }

      _showRedSnack((decoded?['error'] ?? loc.createMatchCreateFailed).toString());
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.createMatchConnectionError);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ---------------- ✅ CREATE MATCH (send host position) ----------------
  Future<void> _onCreatePressed() async {
    final loc = AppLocalizations.of(context)!;

    final b = _selectedBooking;
    final userId = AuthService.userData?['id'];
    final cap = _capacity;

    if (b == null || userId == null) return;

    final bookingId = b['booking_id'];
    if (bookingId == null) {
      _showRedSnack(loc.createMatchBookingIdMissing);
      return;
    }

    final teamSize = cap ~/ 2;
    final hostPos = _selectedBluePosition;

    if (teamSize <= 0 || hostPos == null || hostPos < 1 || hostPos > teamSize) {
      _showRedSnack(loc.createMatchPickValidPositionFirst);
      return;
    }

    // ✅ enforce open slots min=1 at submit time too
    final openSlots = _openSlots.clamp(1, max(1, cap));

    setState(() => _creating = true);

    try {
      final res = await http.post(
        Uri.parse('${apiUrl}users/createMatch'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({
          'booking_id': bookingId,
          'user_id': userId,
          'open_slots': openSlots,
          'position': hostPos,
        }),
      );

      final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showRedSnack(decoded?['message'] ?? loc.createMatchCreatedSuccess);
        Navigator.pop(context, true);
        return;
      }

      final errMsg = (decoded?['error'] ?? loc.createMatchCreateFailed).toString();
      _showRedSnack(errMsg);
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.createMatchConnectionError);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.createMatchTitle)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(child: Text(_error!))
                : _buildContent(),
        bottomNavigationBar: (!_loading && _error == null)
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _canSubmit
                          ? (_openMode ? _onCreateOpenPressed : _onCreatePressed)
                          : null,
                      icon: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sports_soccer),
                      label: Text(_creating ? loc.createMatchCreating : loc.createMatchButton),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildContent() {
    final loc = AppLocalizations.of(context)!;
    final cap = _capacity;

    // ✅ enforce slider minimum 1
    final minOpenSlots = 1;

    // ✅ LIMIT TO capacity-1 (host already occupies 1)
    final maxOpenSlots = (cap > 1) ? (cap - 1) : 1;

    if (_openSlots < minOpenSlots) _openSlots = minOpenSlots;
    if (_openSlots > maxOpenSlots) _openSlots = maxOpenSlots;

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchEligibleBookings();
        await _fetchOpenMatchOptions();
      },
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _modeSelector(),
          const SizedBox(height: 18),

          if (_openMode)
            _openMatchForm()
          else
            ..._bookingPickerSection(),

          const SizedBox(height: 18),

          Text(
            loc.createMatchOpenSlotsQuestion,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          // ✅ min=1 and max=capacity-1 (host takes 1)
          Slider(
            value: _openSlots.toDouble().clamp(minOpenSlots.toDouble(), maxOpenSlots.toDouble()),
            min: minOpenSlots.toDouble(),
            max: maxOpenSlots.toDouble(),
            divisions: (maxOpenSlots - minOpenSlots).clamp(1, 9999),
            label: _openSlots.toString(),
            onChanged: (v) => setState(() => _openSlots = v.round().clamp(minOpenSlots, maxOpenSlots)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$minOpenSlots", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
              Text("$maxOpenSlots", style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),

          const SizedBox(height: 18),

          _formationPreview(capacity: cap, openSlots: _openSlots),
          const SizedBox(height: 18),

          _positionPickerBlue(capacity: cap),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Whether the create button is live, per mode.
  bool get _canSubmit {
    if (_creating) return false;
    if (_selectedBluePosition == null || _capacity <= 0) return false;
    if (_openMode) {
      return _cityId != null &&
          _matchDate != null &&
          _startTime != null &&
          _endTime != null;
    }
    return _eligibleBookings.isNotEmpty;
  }

  Widget _modeSelector() {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.createMatchModeTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
              value: false,
              icon: const Icon(Icons.event_available, size: 18),
              label: Text(loc.createMatchModeBooked),
            ),
            ButtonSegment(
              value: true,
              icon: const Icon(Icons.person_search, size: 18),
              label: Text(loc.createMatchModeOpen),
            ),
          ],
          selected: {_openMode},
          onSelectionChanged: (s) {
            setState(() {
              _openMode = s.first;
              // Capacity comes from a different place in each mode, so the
              // slot count and position have to be re-seeded.
              final cap = _capacity;
              _openSlots = cap > 1 ? max(1, cap ~/ 2) : 1;
              _selectedBluePosition = (_teamSize > 0) ? 1 : null;
            });
          },
        ),
        if (_openMode) ...[
          const SizedBox(height: 8),
          Text(
            loc.createMatchModeOpenHint,
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
        if (!_openMode && _eligibleBookings.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            loc.createMatchModeBookedNoBookings,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- "find players first" form ----------------
  Widget _openMatchForm() {
    final loc = AppLocalizations.of(context)!;
    final fields = _matchingCityFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.createMatchWhereAndWhen,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          initialValue: _cityId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.createMatchCity,
            border: const OutlineInputBorder(),
          ),
          items: _cities.map((c) {
            final id = int.tryParse(c['city_id']?.toString() ?? '');
            final name = (c['city_name'] ?? '').toString();
            return DropdownMenuItem(
              value: id,
              child: Text(_translateCityIfNeeded(name)),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => _cityId = v);
            _fetchCityFields();
          },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<int>(
          initialValue: _fieldTypeId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.createMatchSport,
            border: const OutlineInputBorder(),
          ),
          items: _fieldTypes.map((t) {
            final id = int.tryParse(t['field_type_id']?.toString() ?? '');
            return DropdownMenuItem(
              value: id,
              child: Text((t['field_type'] ?? '').toString()),
            );
          }).toList(),
          onChanged: (v) => setState(() {
            _fieldTypeId = v;
            // The old pick may belong to a different sport now.
            _preferredFieldId = null;
          }),
        ),
        const SizedBox(height: 12),

        // Optional: a venue the host would like. Picking one does NOT reserve
        // anything, it only tells joiners where the host is aiming.
        DropdownButtonFormField<int?>(
          initialValue: _preferredFieldId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: loc.createMatchPreferredField,
            border: const OutlineInputBorder(),
            suffixIcon: _loadingCityFields
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(loc.createMatchAnyField),
            ),
            ...fields.map((f) {
              final id = int.tryParse(f['field_id']?.toString() ?? '');
              final ar = (f['field_name'] ?? '').toString();
              final en = (f['field_english_name'] ?? '').toString();
              final name = _isEnglish
                  ? (en.isNotEmpty ? en : ar)
                  : (ar.isNotEmpty ? ar : en);
              return DropdownMenuItem<int?>(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (v) => setState(() => _preferredFieldId = v),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _pickerTile(
                label: loc.createMatchDate,
                value: _matchDate == null
                    ? loc.createMatchPickDate
                    : _formatBookingDate(_fmtDate(_matchDate!)),
                icon: Icons.calendar_today,
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _matchDate ?? now.add(const Duration(days: 1)),
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 60)),
                  );
                  if (picked != null) setState(() => _matchDate = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _pickerTile(
                label: loc.createMatchStartTime,
                value: _startTime == null
                    ? loc.createMatchPickTime
                    : _fmtTime(_startTime!),
                icon: Icons.schedule,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? const TimeOfDay(hour: 20, minute: 0),
                  );
                  if (picked != null) {
                    setState(() {
                      _startTime = picked;
                      // Default to an hour's play so the host rarely has to
                      // touch the end time at all.
                      _endTime ??= TimeOfDay(
                        hour: (picked.hour + 1) % 24,
                        minute: picked.minute,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pickerTile(
                label: loc.createMatchEndTime,
                value: _endTime == null
                    ? loc.createMatchPickTime
                    : _fmtTime(_endTime!),
                icon: Icons.schedule_outlined,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? const TimeOfDay(hour: 21, minute: 0),
                  );
                  if (picked != null) setState(() => _endTime = picked);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Text(
          loc.createMatchPlayersTotal,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _openTotalSlots > 2
                  ? () => setState(() {
                        _openTotalSlots -= 2;
                        _selectedBluePosition = 1;
                        _openSlots = _openSlots.clamp(1, max(1, _openTotalSlots - 1));
                      })
                  : null,
            ),
            Text(
              "$_openTotalSlots",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _openTotalSlots < 40
                  ? () => setState(() {
                        _openTotalSlots += 2;
                        _selectedBluePosition ??= 1;
                      })
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _notesController,
          maxLength: 200,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: loc.createMatchNotes,
            hintText: loc.createMatchNotesHint,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _pickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _bookingPickerSection() {
    final loc = AppLocalizations.of(context)!;

    if (_eligibleBookings.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(loc.createMatchNoEligibleBookings)),
        ),
      ];
    }

    return [
      Text(
        loc.createMatchSelectBookingTitle,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),

      SizedBox(
        height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _eligibleBookings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = _eligibleBookings[i];

                // ✅ Field name rule:
                // EN -> field_english_name
                // AR -> field_name (fallback to english if missing)
                final fnameAr = (item['field_name'] ?? '').toString().trim();
                final fnameEn = (item['field_english_name'] ?? '').toString().trim();
                final title = _isEnglish
                    ? (fnameEn.isNotEmpty ? fnameEn : (fnameAr.isNotEmpty ? fnameAr : ""))
                    : (fnameAr.isNotEmpty ? fnameAr : (fnameEn.isNotEmpty ? fnameEn : ""));

                // (optional) city + location display using your maps if present
                final cityRaw = (item['city_name'] ?? item['city'] ?? '').toString().trim();
                final locationRaw = (item['field_location'] ?? '').toString().trim();
                final cityShown = cityRaw.isEmpty ? "" : _translateCityIfNeeded(cityRaw);
                final locShown = locationRaw.isEmpty ? "" : _translateLocationIfNeeded(locationRaw);
                final placeText = (cityShown.isNotEmpty && locShown.isNotEmpty)
                    ? "$cityShown • $locShown"
                    : (cityShown.isNotEmpty ? cityShown : locShown);

                final date = _formatBookingDate(item['booking_date']);
                final st = _formatApiTime(item['start_time']);
                final et = _formatApiTime(item['end_time']);

                final itemCap = int.tryParse(
                      (item['field_capacity'] ?? item['capacity'] ?? item['total_slots'] ?? '')
                          .toString(),
                    ) ??
                    0;

                final selected = i == _selectedIndex;

                return GestureDetector(
                  onTap: () => _selectBooking(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 300,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withOpacity(0.25),
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                          : Theme.of(context).colorScheme.surface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.redAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$date • $st - $et',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        if (placeText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  placeText,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.groups, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              loc.createMatchCapacityLabel(itemCap),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
    ];
  }
}

/// ✅ One painter that chooses the canvas style based on kind:
/// football | tennis | padel | basketball | other
class _FieldKindPainter extends CustomPainter {
  final String kind;
  _FieldKindPainter({required this.kind});

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, line);

    void drawSimple() {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, line);
      final spot = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, spot);
    }

    if (kind == "football") {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 34, line);

      final spot = Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, spot);

      final boxH = size.height * 0.17;
      final boxW = size.width * 0.56;
      canvas.drawRect(Rect.fromLTWH((size.width - boxW) / 2, 2, boxW, boxH), line);
      canvas.drawRect(
        Rect.fromLTWH((size.width - boxW) / 2, size.height - boxH - 2, boxW, boxH),
        line,
      );

      final smallH = size.height * 0.08;
      final smallW = size.width * 0.36;
      canvas.drawRect(Rect.fromLTWH((size.width - smallW) / 2, 2, smallW, smallH), line);
      canvas.drawRect(
        Rect.fromLTWH((size.width - smallW) / 2, size.height - smallH - 2, smallW, smallH),
        line,
      );
      return;
    }

    if (kind == "tennis" || kind == "padel") {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);

      final marginX = size.width * 0.12;
      canvas.drawLine(Offset(marginX, 2), Offset(marginX, size.height - 2), line);
      canvas.drawLine(Offset(size.width - marginX, 2), Offset(size.width - marginX, size.height - 2), line);

      final serviceYTop = size.height * 0.30;
      final serviceYBottom = size.height * 0.70;
      canvas.drawLine(Offset(marginX, serviceYTop), Offset(size.width - marginX, serviceYTop), line);
      canvas.drawLine(Offset(marginX, serviceYBottom), Offset(size.width - marginX, serviceYBottom), line);

      canvas.drawLine(Offset(size.width / 2, serviceYTop), Offset(size.width / 2, serviceYBottom), line);
      return;
    }

    if (kind == "basketball") {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 26, line);

      final arcR = size.width * 0.22;
      final topCenter = Offset(size.width / 2, size.height * 0.10);
      final bottomCenter = Offset(size.width / 2, size.height * 0.90);

      canvas.drawArc(Rect.fromCircle(center: topCenter, radius: arcR), 0, pi, false, line);
      canvas.drawArc(Rect.fromCircle(center: bottomCenter, radius: arcR), pi, pi, false, line);
      return;
    }

    drawSimple();
  }

  @override
  bool shouldRepaint(covariant _FieldKindPainter oldDelegate) => oldDelegate.kind != kind;
}
