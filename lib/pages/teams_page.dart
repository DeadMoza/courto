// lib/pages/matchmakingPages/teams_page.dart
import 'dart:convert';

import 'package:courto/constants.dart'; // AppFormat
import 'package:courto/pages/matchmakingPages/create_match_page.dart';
import 'package:courto/pages/matchmakingPages/match_details_page.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:courto/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TeamsPage extends StatefulWidget {
  final int cityId;

  const TeamsPage({
    super.key,
    required this.cityId,
  });

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final apiUrl = dotenv.env['API_URL'];

  bool _loadingMatches = true;
  String? _matchesError; // translation key
  List<Map<String, dynamic>> _matches = [];

  int? get _myUserId => AuthService.userData?['id'];

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

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  @override
  void didUpdateWidget(covariant TeamsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) {
      _fetchMatches();
    }
  }

  Future<void> _fetchMatches() async {
    _loadingMatches = true;
    _matchesError = null;
    if (mounted) setState(() {});

    try {
      final myId = _myUserId;

      final uri = Uri.parse('${apiUrl}users/getMatches/${widget.cityId}/$myId');

      final res = await http.get(
        uri,
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _matches = List<Map<String, dynamic>>.from(data['data'] ?? []);
        print(_matches);
      } else {
        // ignore: avoid_print
        print("getMatches status=${res.statusCode} body=${res.body}");
        _matchesError = "errorLoadMatches";
        _matches = [];
      }
    } catch (e) {
      // ignore: avoid_print
      print("fetchMatches error: $e");
      _matchesError = "errorConnection";
      _matches = [];
    } finally {
      _loadingMatches = false;
      if (mounted) setState(() {});
    }
  }

  // -------------------- helpers --------------------
  dynamic _getMatchKey(Map<String, dynamic> m) => m['match_id'] ?? m['id'];

  DateTime? _parseDate(dynamic bookingDate) {
    if (bookingDate == null) return null;
    try {
      return DateTime.parse(bookingDate.toString());
    } catch (_) {
      return null;
    }
  }

  // ✅ English months when app is English, Arabic months when app is Arabic
  String _formatBookingDate(dynamic bookingDate) {
    final dt = _parseDate(bookingDate);
    if (dt == null) return bookingDate?.toString() ?? '';

    final lang = Intl.getCurrentLocale(); // "ar" or "en"
    if (lang.startsWith('en')) {
      return DateFormat('d MMM y', 'en').format(dt);
    }
    return AppFormat.formatDateArabic(dt);
  }

  String _formatApiTime(dynamic time) {
    if (time == null) return '';
    return AppFormat.formatArabicTime(time.toString());
  }

  String _getFieldLocationRaw(Map<String, dynamic> m) {
    return (m['field_location'] ?? '').toString().trim();
  }

  String _getCityRaw(Map<String, dynamic> m) {
    return (m['city_name'] ?? m['city'] ?? '').toString().trim();
  }

  String _translateCityIfNeeded(BuildContext context, String cityArOrAny) {
    final isAr = Localizations.localeOf(context).languageCode == "ar";
    if (isAr) return cityArOrAny;
    return _cityEnMap[cityArOrAny] ?? cityArOrAny;
  }

  String _translateLocationIfNeeded(BuildContext context, String locArOrAny) {
    final isAr = Localizations.localeOf(context).languageCode == "ar";
    if (isAr) return locArOrAny;
    return _locationEnMap[locArOrAny] ?? locArOrAny;
  }

  bool _isMyHostedMatch(Map<String, dynamic> m) {
    final myId = _myUserId;
    if (myId == null) return false;

    final hostId = m['host_user_id'] ?? m['user_id'];
    final host = int.tryParse(hostId?.toString() ?? '');
    if (host == null || host != myId) return false;

    final status = (m['status'] ?? 'open').toString();
    if (status != 'open') return false;

    final closeStr = m['close_time']?.toString();
    if (closeStr != null && closeStr.isNotEmpty) {
      try {
        final closeDt = DateTime.parse(closeStr);
        if (closeDt.isBefore(DateTime.now())) return false;
      } catch (_) {}
    }

    return true;
  }

  // ✅ Uses backend-provided i_joined (preferred)
  bool _isMatchJoinedByMe(Map<String, dynamic> m) {
    final v = m['i_joined'];

    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 't' || s == 'yes';
    }

    // fallback to older shapes if present
    final myId = _myUserId;
    if (myId == null) return false;

    final myStatus = (m['my_status'] ?? '').toString();
    if (myStatus.isNotEmpty) return true;

    final ids = m['joined_user_ids'];
    if (ids is List) {
      return ids.any((x) => int.tryParse(x.toString()) == myId);
    }

    return false;
  }

  IconData _fieldTypeIcon(Map<String, dynamic> m) {
    final typeStr = (m['field_type'] ?? '').toString().toLowerCase();

    if (typeStr.contains("padel")) return Icons.sports_tennis;
    if (typeStr.contains("basket")) return Icons.sports_basketball;
    if (typeStr.contains("tennis")) return Icons.sports_tennis;
    if (typeStr.contains("volley")) return Icons.sports_volleyball;
    if (typeStr.contains("football") || typeStr.contains("soccer")) return Icons.sports_soccer;

    final typeId = int.tryParse((m['type_id'] ?? m['field_type_id'] ?? '').toString());
    if (typeId == 1) return Icons.sports_soccer;

    return Icons.sports;
  }

  // -------------------- UI bits --------------------
  Widget _statusBadge(BuildContext context, String status, {bool highlight = false}) {
    final loc = AppLocalizations.of(context)!;
    final s = status.isEmpty ? 'open' : status;

    String label;
    Color bg;
    Color fg;

    switch (s) {
      case 'closed':
        label = loc.matchStatusClosed;
        bg = Colors.grey.withOpacity(0.15);
        fg = Colors.grey.shade700;
        break;
      case 'open':
      default:
        label = highlight ? loc.matchStatusActive : loc.matchStatusOpen;
        bg = Theme.of(context).colorScheme.primary.withOpacity(0.12);
        fg = Theme.of(context).colorScheme.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: fg)),
    );
  }

  Widget _tagBadge(BuildContext context, {required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: color)),
    );
  }

  Widget _pill(BuildContext context, {required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    Map<String, dynamic> m, {
    bool highlight = false,
    bool isJoined = false,
  }) {
    final loc = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == "ar";

    final owner = (m['match_owner'] ?? '').toString().trim();

    // EN -> field_english_name, AR -> field_name
    final fieldTitle = isAr
        ? (m['field_name'] ?? '').toString()
        : (m['field_english_name'] ?? '').toString();

    // A match posted before any booking has no venue, or only one the host
    // fancies. Saying so up front stops anyone turning up at a pitch nobody
    // reserved.
    final hasBooking = m['has_booking'] != false;
    final String title;
    if (hasBooking) {
      title = fieldTitle.isNotEmpty ? fieldTitle : loc.fieldFallback;
    } else if (fieldTitle.isNotEmpty) {
      title = loc.matchSuggestedField(fieldTitle);
    } else {
      title = loc.matchVenueNotBookedYet;
    }

    final bookingDate = _formatBookingDate(m['booking_date']);
    final startTime = _formatApiTime(m['start_time']);
    final endTime = _formatApiTime(m['end_time']);

    final totalSlots = int.tryParse((m['total_slots'] ?? '0').toString()) ?? 0;
    final remainingSlots = int.tryParse((m['remaining_slots'] ?? '0').toString()) ?? 0;
    final slotsCount = totalSlots - remainingSlots - 1;

    final status = (m['status'] ?? 'open').toString();
    final typeIcon = _fieldTypeIcon(m);

    final cityRaw = _getCityRaw(m);
    final locationRaw = _getFieldLocationRaw(m);

    final cityShown = cityRaw.isEmpty ? "" : _translateCityIfNeeded(context, cityRaw);
    final locationShown = locationRaw.isEmpty ? "" : _translateLocationIfNeeded(context, locationRaw);

    final placeText = (cityShown.isNotEmpty && locationShown.isNotEmpty)
        ? "$cityShown • $locationShown"
        : (cityShown.isNotEmpty ? cityShown : locationShown);

    return Card(
      elevation: highlight ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final matchId = int.tryParse((m['match_id'] ?? m['id']).toString());
          if (matchId == null) return;

          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MatchDetailsPage(matchId: matchId)),
          );

          await _fetchMatches();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      owner.isNotEmpty ? owner : loc.userFallback,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.redAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!hasBooking) ...[
                    const SizedBox(width: 8),
                    _tagBadge(context, text: loc.badgeNoVenue, color: Colors.deepOrange),
                  ],
                  if (isJoined) ...[
                    const SizedBox(width: 8),
                    _tagBadge(context, text: loc.badgeJoined, color: Colors.orange),
                  ],
                  const SizedBox(width: 8),
                  _statusBadge(context, status, highlight: highlight),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(typeIcon, size: 20, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: hasBooking ? null : Colors.deepOrange.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (placeText.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        placeText,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '$bookingDate • $startTime - $endTime',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (totalSlots > 0)
                    _pill(
                      context,
                      icon: Icons.groups,
                      text: loc.playersCount(slotsCount, totalSlots),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCreateMatchPressed() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CreateMatchPage(initialCityId: widget.cityId),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      await _fetchMatches();
    }
  }

  String _errorText(BuildContext context, String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case "errorLoadMatches":
        return loc.errorLoadMatches;
      case "errorConnection":
        return loc.errorConnection;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final matches = _matches;

    // host matches pinned first. A user can now hold both a booked match and
    // one they posted before booking, so all of them are pinned, not just the
    // first - otherwise the second would be buried down in "browse".
    final myHosted = matches.where(_isMyHostedMatch).toList();
    final myHostedKeys = myHosted.map(_getMatchKey).toSet();

    // joined (excluding anything they host)
    final joined = matches
        .where(_isMatchJoinedByMe)
        .where((m) => !myHostedKeys.contains(_getMatchKey(m)))
        .toList();

    final joinedKeys = joined.map(_getMatchKey).toSet();

    // browse = everything else (excluding hosted + joined)
    final browse = matches
        .where((m) => !myHostedKeys.contains(_getMatchKey(m)))
        .where((m) => !joinedKeys.contains(_getMatchKey(m)))
        .toList();

    final body = _loadingMatches
        ? const Center(child: CircularProgressIndicator())
        : (_matchesError != null)
            ? Center(child: Text(_errorText(context, _matchesError!)))
            : RefreshIndicator(
                onRefresh: _fetchMatches,
                child: _buildList(context, myHosted, joined, browse),
              );

    return Scaffold(
      floatingActionButton: (myHosted.isEmpty)
          ? FloatingActionButton.extended(
              onPressed: _onCreateMatchPressed,
              icon: const Icon(Icons.add),
              label: Text(loc.createMatch),
            )
          : null,
      body: body,
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> myHosted,
    List<Map<String, dynamic>> joined,
    List<Map<String, dynamic>> browse,
  ) {
    final loc = AppLocalizations.of(context)!;

    final nothing = myHosted.isEmpty && joined.isEmpty && browse.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (nothing)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text(loc.noMatchesNow)),
          ),

        if (myHosted.isNotEmpty) ...[
          _sectionTitle(loc.sectionMyMatch),
          ...myHosted.map(
            (m) => _buildMatchCard(context, m, highlight: true, isJoined: false),
          ),
          const SizedBox(height: 12),
          const Divider(height: 28),
        ],

        if (joined.isNotEmpty) ...[
          _sectionTitle(loc.sectionJoinedMatches),
          ...joined.map((m) => _buildMatchCard(context, m, isJoined: true)).toList(),
          const SizedBox(height: 12),
          const Divider(height: 28),
        ],

        if (browse.isNotEmpty) ...[
          _sectionTitle(loc.sectionBrowseMatches),
          ...browse.map((m) => _buildMatchCard(context, m, isJoined: false)).toList(),
        ],

        const SizedBox(height: 90),
      ],
    );
  }
}
