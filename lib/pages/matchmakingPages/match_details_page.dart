// lib/pages/matchmakingPages/match_details_page.dart
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';


import 'package:courto/constants.dart'; // must contain FormationRepo + AppFormat
import 'package:courto/l10n/app_localizations.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MatchDetailsPage extends StatefulWidget {
  final int matchId;
  const MatchDetailsPage({super.key, required this.matchId});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> {
  final apiUrl = dotenv.env['API_URL'];

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _matchInfo;
  List<Map<String, dynamic>> _players = [];

  bool _loadingRequests = false;
  List<Map<String, dynamic>> _requests = []; // waiting+joined from getMatchRequests

  int? get _myUserId => AuthService.userData?['id'];
  int? get _hostUserId => int.tryParse((_matchInfo?['host_user_id'] ?? '').toString());

  int get _totalSlots => int.tryParse((_matchInfo?['total_slots'] ?? '0').toString()) ?? 0;
  int get _openSlots => int.tryParse((_matchInfo?['open_slots'] ?? '0').toString()) ?? 0;

  // Host occupies 1 slot; joiners allowed = open_slots
  int get _maxJoined => (_openSlots + 1).clamp(1, 9999);

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }


void _showPlayerInfoSheet(Map<String, dynamic> p) {
  final loc = AppLocalizations.of(context)!;

  final fullName = (p['full_name'] ?? '').toString().trim();
  final phoneRaw = (p['phone_number'] ?? '').toString().trim();

  String normalizePhoneForCopy(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\s+'), '');

    // Remove +
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Replace 218 with 0
    if (cleaned.startsWith('218')) {
      cleaned = '0${cleaned.substring(3)}';
    }

    return cleaned;
  }

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fullName.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person),
                title: Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),

            if (phoneRaw.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone),
                title: GestureDetector(
                  onTap: () async {
                    final formatted = normalizePhoneForCopy(phoneRaw);
                    await Clipboard.setData(
                      ClipboardData(text: formatted),
                    );

                    if (!mounted) return;
                  },
                  child: Text(
                    phoneRaw,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    final formatted = normalizePhoneForCopy(phoneRaw);
                    await Clipboard.setData(
                      ClipboardData(text: formatted),
                    );

                    if (!mounted) return;
                  },
                ),
              ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.commonBack),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

  // ===================== Snack (RED) =====================
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

  // ===================== API =====================

  Future<void> _fetchMatchDetails() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${apiUrl}users/getMatchDetails/${widget.matchId}'),
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final matchInfo = Map<String, dynamic>.from(data['match_info'] ?? {});
        final playersRaw = data['players'] is List ? data['players'] as List : [];
        final players = playersRaw.map((e) => Map<String, dynamic>.from(e)).toList();

        if (!mounted) return;
        setState(() {
          _matchInfo = matchInfo;
          _players = players;
          _loading = false;
        });

        if (_isHost()) {
          await _fetchMatchRequests();
        }
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = AppLocalizations.of(context)!.matchDetailsLoadFailed;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.commonConnectionError;
      });
    }
  }

  Future<void> _fetchMatchRequests() async {
    if (!_isHost()) return;

    if (!mounted) return;
    setState(() => _loadingRequests = true);

    try {
      final res = await http.get(
        Uri.parse('${apiUrl}users/getMatchRequests/${widget.matchId}'),
        headers: {
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rows = List<Map<String, dynamic>>.from(data['data'] ?? data ?? []);
        if (!mounted) return;
        setState(() => _requests = rows);
      }
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  // ===================== Helpers =====================

  String _firstName(String fullName) {
    final loc = AppLocalizations.of(context)!;
    final s = fullName.trim();
    if (s.isEmpty) return loc.commonUser;
    final parts = s.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : s;
  }

  bool _isHost() {
    final me = _myUserId;
    final host = _hostUserId;
    if (me == null || host == null) return false;
    return me == host;
  }

  bool _isMeInMatch() {
    final me = _myUserId;
    if (me == null) return false;
    return _players.any((p) {
      final status = (p['status'] ?? '').toString();
      return int.tryParse(p['user_id']?.toString() ?? '') == me && status == 'joined';
    });
  }

  bool _isMyPendingRequest() {
    final me = _myUserId;
    if (me == null) return false;
    return _players.any((p) {
      final uid = int.tryParse(p['user_id']?.toString() ?? '');
      final status = (p['status'] ?? '').toString();
      return uid == me && status == 'waiting';
    });
  }

  int _joinedCount() => _players.where((p) => (p['status'] ?? '').toString() == 'joined').length;

  bool _isMatchFullForJoiners() => _joinedCount() >= _maxJoined;

  int _teamSize() {
    final total = _totalSlots;
    if (total <= 0) return 0;
    return total ~/ 2; // capacities are even (2..22)
  }

  Map<String, dynamic>? _joinedPlayerAt(String team, int position) {
    for (final p in _players) {
      if ((p['status'] ?? '').toString() != 'joined') continue;
      if ((p['team'] ?? '').toString() != team) continue;
      final pos = int.tryParse((p['position'] ?? '').toString());
      if (pos == position) return p;
    }
    return null;
  }

  int _waitingRequestsCountForSlot(String team, int position) {
    if (!_isHost()) return 0;
    return _requests.where((r) {
      final st = (r['status'] ?? '').toString();
      if (st != 'waiting') return false;
      final t = (r['team'] ?? '').toString();
      if (t != team) return false;
      final pos = int.tryParse((r['team_position'] ?? r['position'] ?? '').toString()) ?? -1;
      return pos == position;
    }).length;
  }

  // ✅ English months when app is English, Arabic months when app is Arabic
  String _formatBookingDate(dynamic bookingDate) {
    try {
      final dt = DateTime.parse(bookingDate.toString());
      final lang = Intl.getCurrentLocale(); // "ar" / "en"
      if (lang.startsWith('en')) {
        return DateFormat('d MMM y', 'en').format(dt); // e.g. 16 Feb 2026
      }
      return AppFormat.formatDateArabic(dt); // Arabic months
    } catch (_) {
      return bookingDate?.toString() ?? '';
    }
  }

  String _formatApiTime(dynamic time) {
    if (time == null) return '';
    return AppFormat.formatArabicTime(time.toString()); // AM/PM in EN, ص/م in AR
  }

  String _getCityRaw() => (_matchInfo?['city_name'] ?? _matchInfo?['city'] ?? '').toString().trim();
  String _getLocationRaw() => (_matchInfo?['field_location'] ?? '').toString().trim();

  String _translateCityIfNeeded(String cityArOrAny) {
    final isAr = Localizations.localeOf(context).languageCode == "ar";
    if (isAr) return cityArOrAny;
    return _cityEnMap[cityArOrAny] ?? cityArOrAny;
  }

  String _translateLocationIfNeeded(String locArOrAny) {
    final isAr = Localizations.localeOf(context).languageCode == "ar";
    if (isAr) return locArOrAny;
    return _locationEnMap[locArOrAny] ?? locArOrAny;
  }

  // ===================== Field type (icon + canvas kind + label) =====================

  String _fieldTypeRaw() => (_matchInfo?['field_type'] ?? '').toString().toLowerCase();

  String _fieldKind() {
    final t = _fieldTypeRaw();
    if (t.contains("football") || t.contains("soccer")) return "football";
    if (t.contains("padel")) return "padel";
    if (t.contains("tennis")) return "tennis";
    if (t.contains("basket")) return "basketball";
    return "other";
  }

  IconData _fieldTypeIcon() {
    switch (_fieldKind()) {
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

  String _fieldTypeLabel() {
    final loc = AppLocalizations.of(context)!;
    switch (_fieldKind()) {
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

  // ===================== Dot alignment: safe offsets =====================

  List<ui.Offset> _safeTeamOffsets({required int totalSlots, required int teamSize}) {
    if (teamSize <= 0) return const [];

    // FormationRepo returns normalized offsets (0..1). We ensure we have enough.
    final raw = FormationRepo.getTeamOffsets(totalSlots).map((o) => ui.Offset(o.dx, o.dy)).toList();

    List<ui.Offset> base = raw.length >= teamSize ? raw.take(teamSize).toList() : <ui.Offset>[];

    if (base.length < teamSize) {
      final auto = FormationRepo.autoGenerate(teamSize: teamSize).map((o) => ui.Offset(o.dx, o.dy)).toList();
      base = auto.length >= teamSize ? auto.take(teamSize).toList() : <ui.Offset>[];
    }

    // ultimate fallback: vertical line centered
    if (base.length < teamSize) {
      base = List<ui.Offset>.generate(teamSize, (i) {
        final y = 0.85 - (i * (0.70 / max(1, teamSize - 1)));
        return ui.Offset(0.5, y);
      });
    }

    return base;
  }

  // ===================== Join request (slot-based) =====================

  Future<void> _sendJoinRequest({required String team, required int position}) async {
    final loc = AppLocalizations.of(context)!;
    final me = _myUserId;
    if (me == null) return;

    try {
      final res = await http.post(
        Uri.parse('${apiUrl}users/createMatchRequest'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({
          'match_id': widget.matchId,
          'user_id': me,
          'team': team,
          'position': position,
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showRedSnack(loc.matchDetailsJoinRequestSent);
        await _fetchMatchDetails();
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _showRedSnack((data['error'] ?? loc.matchDetailsJoinRequestFailed).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.commonConnectionError);
    }
  }

  Future<void> _confirmJoinSlot({required String team, required int position}) async {
    final loc = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.matchDetailsJoinRequestTitle),
        content: Text(
          loc.matchDetailsJoinRequestConfirm(
            team == 'blue' ? loc.matchDetailsTeamBlue : loc.matchDetailsTeamRed,
            position,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.commonCancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _sendJoinRequest(team: team, position: position);
            },
            child: Text(loc.matchDetailsSendRequest),
          ),
        ],
      ),
    );
  }

  // ===================== Host: accept/reject + slot sheet =====================

  Future<void> _acceptRequest(int requestId) async {
    final loc = AppLocalizations.of(context)!;
    final me = _myUserId;
    if (me == null) return;

    try {
      final res = await http.post(
        Uri.parse('${apiUrl}users/acceptMatchRequest'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({'request_id': requestId, 'host_user_id': me}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showRedSnack(loc.matchDetailsRequestAccepted);
        await _fetchMatchDetails();
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _showRedSnack((data['error'] ?? loc.matchDetailsAcceptFailed).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.commonConnectionError);
    }
  }

  Future<void> _rejectRequest(int requestId) async {
    final loc = AppLocalizations.of(context)!;
    final me = _myUserId;
    if (me == null) return;

    try {
      final res = await http.delete(
        Uri.parse('${apiUrl}users/rejectMatchRequest'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({'request_id': requestId, 'host_user_id': me}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _showRedSnack(loc.matchDetailsRequestRejected);
        await _fetchMatchDetails();
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _showRedSnack((data['error'] ?? loc.matchDetailsRejectFailed).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.commonConnectionError);
    }
  }

  Future<void> _showSlotRequestsSheet({required String team, required int position}) async {
    final loc = AppLocalizations.of(context)!;

    await _fetchMatchRequests();

    final slotRequests = _requests.where((r) {
      final st = (r['status'] ?? '').toString();
      final t = (r['team'] ?? '').toString();
      final pos = int.tryParse((r['team_position'] ?? r['position'] ?? '').toString()) ?? -1;
      return st == 'waiting' && t == team && pos == position;
    }).toList();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.matchDetailsSlotRequestsTitle(
                        position,
                        team == 'blue' ? loc.matchDetailsTeamBlue : loc.matchDetailsTeamRed,
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (_loadingRequests)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
              const SizedBox(height: 10),
              if (slotRequests.isEmpty)
                Text(
                  loc.matchDetailsNoRequestsForSlot,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                )
              else
                ...slotRequests.map((r) {
                  final name = (r['full_name'] ?? loc.commonUser).toString();
                  final phone = (r['phone_number'] ?? '').toString();
                  final id = int.tryParse((r['id'] ?? '').toString()) ?? 0;

                  return Card(
                    child: ListTile(
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: phone.isEmpty ? null : Text(phone),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: loc.matchDetailsReject,
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _rejectRequest(id);
                            },
                            icon: const Icon(Icons.close),
                          ),
                          IconButton(
                            tooltip: loc.matchDetailsAccept,
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _acceptRequest(id);
                            },
                            icon: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

    // ===================== Leave match (joined users only) =====================

  Future<void> _leaveMatch() async {
    final loc = AppLocalizations.of(context)!;
    final me = _myUserId;
    if (me == null) return;

    try {
      final res = await http.delete(
        Uri.parse('${apiUrl}users/leaveMatch'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({'match_id': widget.matchId, 'user_id': me}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        final ok = data['success'] == true;

        _showRedSnack(ok ? loc.matchDetailsLeftMatch : (data['message'] ?? loc.matchDetailsLeaveFailed).toString());

        if (ok) {
          Navigator.of(context).pop(true); // refresh Teams page
        }
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _showRedSnack((data['error'] ?? loc.matchDetailsLeaveFailed).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.commonConnectionError);
    }
  }

  Future<void> _confirmLeaveMatch() async {
    final loc = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.matchDetailsLeaveTitle),
        content: Text(loc.matchDetailsLeaveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.commonBack)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _leaveMatch();
            },
            child: Text(loc.matchDetailsLeaveButton),
          ),
        ],
      ),
    );
  }


  // ===================== Cancel match (host only) =====================

  Future<void> _cancelMatch() async {
    final loc = AppLocalizations.of(context)!;
    final me = _myUserId;
    if (me == null) return;

    try {
      final res = await http.delete(
        Uri.parse('${apiUrl}users/cancelMatch'),
        headers: {
          'Content-Type': 'application/json',
          'authorization': 'Bearer ${AuthService.token}',
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({'match_id': widget.matchId, 'user_id': me}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        final ok = data['success'] == true;

        _showRedSnack(ok ? loc.matchDetailsCanceled : loc.matchDetailsCancelFailed);

        if (ok) Navigator.of(context).pop(true);
      } else {
        final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};
        _showRedSnack((data['error'] ?? loc.matchDetailsCancelFailed).toString());
      }
    } catch (_) {
      if (!mounted) return;
      _showRedSnack(loc.commonConnectionError);
    }
  }

  Future<void> _confirmCancelMatch() async {
    final loc = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.matchDetailsCancelTitle),
        content: Text(loc.matchDetailsCancelConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.commonBack)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _cancelMatch();
            },
            child: Text(loc.matchDetailsCancelButton),
          ),
        ],
      ),
    );
  }

  // ===================== Formation Board =====================

  Widget _formationBoard({
    required String team,
    required Color color,
    required String title,
  }) {
    final loc = AppLocalizations.of(context)!;
    final teamSize = _teamSize();
    if (teamSize <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            loc.matchDetailsNoCapacityFormation,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    // ✅ aligned offsets (guaranteed teamSize)
    final baseOffsets = _safeTeamOffsets(totalSlots: _totalSlots, teamSize: teamSize);

    // ✅ make teams face each other:
    // blue: vertical flip (y -> 1-y)
    // red : mirror horizontally (x -> 1-x)
    final offsets = (team == 'blue')
        ? baseOffsets.map((o) => ui.Offset(o.dx, 1 - o.dy)).toList()
        : baseOffsets.map((o) => ui.Offset(1 - o.dx, o.dy)).toList();

    final matchFull = _isMatchFullForJoiners();
    final canTapToJoin = !_isHost() && !_isMeInMatch() && !_isMyPendingRequest() && !matchFull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 320,
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final h = c.maxHeight;

                  ui.Offset mapToCanvas(ui.Offset n) {
                    const pad = 12.0; // ✅ a bit more padding to avoid edge clipping
                    final x = pad + n.dx * (w - pad * 2);
                    final y = pad + n.dy * (h - pad * 2);
                    return ui.Offset(x, y);
                  }

                  Widget slotDot(int pos, ui.Offset center) {
                    final joined = _joinedPlayerAt(team, pos);
                    final isJoined = joined != null;

                    final bool host = _isHost();

                    // host can tap joined OR empty
                    final bool isTapEnabled = host ? true : (!isJoined && canTapToJoin);


                    final border = isJoined ? color : Colors.grey.withOpacity(0.55);
                    final fill = isJoined ? color : Colors.transparent;

                    final label = isJoined ? _firstName((joined['full_name'] ?? '').toString()) : "";

                    final reqCount = (!isJoined && _isHost()) ? _waitingRequestsCountForSlot(team, pos) : 0;

                    return Positioned(
                      left: center.dx - 18,
                      top: center.dy - 18,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: !isTapEnabled
                            ? null
                            : () async {
                                if (host) {
                                  if (isJoined) {
                                    _showPlayerInfoSheet(joined);
                                    return;
                                  }
                                  await _showSlotRequestsSheet(team: team, position: pos);
                                } else {
                                  await _confirmJoinSlot(team: team, position: pos);
                                }
                              },

                        child: SizedBox(
                          width: 44,
                          height: 58,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: fill,
                                      border: Border.all(color: border, width: 2.2),
                                    ),
                                    child: isJoined
                                        ? const Icon(Icons.person, size: 14, color: Colors.white)
                                        : (isTapEnabled
                                            ? Icon(
                                                Icons.add,
                                                size: 14,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              )
                                            : null),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isJoined ? color : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),

                              // ✅ yellow requests count badge (host only, empty slot only)
                              if (reqCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: Colors.black.withOpacity(0.15)),
                                    ),
                                    child: Text(
                                      reqCount.toString(),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final dots = <Widget>[];
                  for (int i = 0; i < teamSize; i++) {
                    final position = i + 1; // 1..teamSize
                    final center = mapToCanvas(offsets[i]); // ✅ now always aligned
                    dots.add(slotDot(position, center));
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TeamFieldPainter(
                            color: color.withOpacity(0.18),
                            kind: _fieldKind(),
                            team: team,
                          ),
                        ),
                      ),
                      ...dots,
                      if (!_isHost() && matchFull)
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              loc.matchDetailsJoinSlotsFull,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == "ar";

    return Directionality(
      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.matchDetailsTitle),
          actions: [
            IconButton(onPressed: _fetchMatchDetails, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
                ? Center(child: Text(_error!))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final loc = AppLocalizations.of(context)!;
    final info = _matchInfo ?? {};
        final isAr = Localizations.localeOf(context).languageCode == "ar";


    final hostFullName = (info['match_owner'] ?? '').toString().trim();
    final hostName = hostFullName.isNotEmpty ? hostFullName : loc.commonUser;

    // ✅ ALWAYS use field_english_name (as requested)
    final fieldEn = isAr ? (info['field_name'] ?? '').toString().trim() : (info['field_english_name'] ?? '').toString().trim();
    final title = fieldEn.isNotEmpty ? fieldEn : loc.matchDetailsFieldFallback;

    // ✅ city + location maps
    final cityRaw = _getCityRaw();
    final locRaw = _getLocationRaw();
    final cityShown = cityRaw.isEmpty ? "" : _translateCityIfNeeded(cityRaw);
    final locationShown = locRaw.isEmpty ? "" : _translateLocationIfNeeded(locRaw);

    final placeText = (cityShown.isNotEmpty && locationShown.isNotEmpty)
        ? "$cityShown • $locationShown"
        : (cityShown.isNotEmpty ? cityShown : locationShown);

    final date = _formatBookingDate(info['booking_date']);
    final st = _formatApiTime(info['start_time']);
    final et = _formatApiTime(info['end_time']);

    final typeIcon = _fieldTypeIcon();
    final typeLabel = _fieldTypeLabel();

    final remainingJoinSlots = (_maxJoined - _joinedCount()).clamp(0, 9999);

    return RefreshIndicator(
      onRefresh: _fetchMatchDetails,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // host + field type icon + label
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hostName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.redAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (placeText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            placeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  Text(
                    '$date • $st - $et',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(icon: Icons.groups, text: loc.matchDetailsRemainingSlots(remainingJoinSlots)),
                      if (_isHost()) _pill(icon: Icons.verified_user, text: loc.matchDetailsYouAreHost),
                      if (_isMeInMatch() && !_isHost()) _pill(icon: Icons.check_circle, text: loc.matchDetailsYouJoined),
                      if (_isMyPendingRequest()) _pill(icon: Icons.hourglass_bottom, text: loc.matchDetailsPendingReview),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          _formationBoard(team: 'blue', color: Colors.blue, title: loc.matchDetailsBlueFormation),
          const SizedBox(height: 12),
          _formationBoard(team: 'red', color: Colors.red, title: loc.matchDetailsRedFormation),

          const SizedBox(height: 18),

          if (_isHost())
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmCancelMatch,
                icon: const Icon(Icons.cancel),
                label: Text(
                  loc.matchDetailsCancelButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),

          // ✅ leave button for joined users (non-host)
          if (!_isHost() && _isMeInMatch()) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _confirmLeaveMatch,
                icon: const Icon(Icons.exit_to_app),
                label: Text(
                  loc.matchDetailsLeaveButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
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
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Paints different canvases by field type:
/// - football: midline + circle + penalty/goal boxes
/// - tennis/padel: net + service boxes
/// - basketball: center line + circle + arcs
/// - other: simple
class _TeamFieldPainter extends CustomPainter {
  final Color color;
  final String kind; // football | tennis | padel | basketball | other
  final String team; // blue | red

  _TeamFieldPainter({
    required this.color,
    required this.kind,
    required this.team,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final line = Paint()
      ..color = color.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, border);

    void drawSimple() {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 36, line);
    }

    if (kind == "football") {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 36, line);

      final isBlue = team == 'blue';

      final boxW = size.width * 0.44;
      final boxH = size.height * 0.16;
      final left = (size.width - boxW) / 2;
      final top = isBlue ? 2.0 : (size.height - 2 - boxH);
      canvas.drawRect(Rect.fromLTWH(left, top, boxW, boxH), line);

      final gW = size.width * 0.22;
      final gH = size.height * 0.08;
      final gLeft = (size.width - gW) / 2;
      final gTop = isBlue ? 2.0 : (size.height - 2 - gH);
      canvas.drawRect(Rect.fromLTWH(gLeft, gTop, gW, gH), line);

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
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, line);

      final arcR = size.width * 0.22;
      final topCenter = Offset(size.width / 2, size.height * 0.10);
      final bottomCenter = Offset(size.width / 2, size.height * 0.90);

      canvas.drawArc(Rect.fromCircle(center: topCenter, radius: arcR), 0, 3.14159, false, line);
      canvas.drawArc(Rect.fromCircle(center: bottomCenter, radius: arcR), 3.14159, 3.14159, false, line);
      return;
    }

    drawSimple();
  }

  @override
  bool shouldRepaint(covariant _TeamFieldPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.kind != kind || oldDelegate.team != team;
  }
}
