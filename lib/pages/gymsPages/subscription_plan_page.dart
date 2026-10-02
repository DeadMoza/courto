import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:courto/image_viewer.dart';

// ---------------------------------------------------------------------------
// SubscriptionPlanPage
// ---------------------------------------------------------------------------
class SubscriptionPlanPage extends StatefulWidget {
  /// Pass ALL plans so the user can switch between them on this page.
  final List<Map<String, dynamic>> plans;

  /// Index of the plan that was tapped (default selection).
  final int initialIndex;

  const SubscriptionPlanPage({
    super.key,
    required this.plans,
    this.initialIndex = 0,
  });

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage>
    with TickerProviderStateMixin {

  // ── Selected plan ─────────────────────────────────────────────────────────
  late int _planIndex;

  /// A local copy of what we were handed, so a plan can be refreshed in place.
  /// The list this page is pushed with was loaded a screen ago, and the places
  /// count is the one thing on here that goes out of date while it is open.
  late List<Map<String, dynamic>> _plans;

  Map<String, dynamic> get _plan => _plans[_planIndex];

  // ── Duration selector ─────────────────────────────────────────────────────
  String _durationType = 'monthly';

  static const Map<String, String> _planTypeImage = {
    'chess':    'assets/images/courtoChess.png',
    'academy':  'assets/images/courtoTeams.jpg',
    'swimming': 'assets/images/courtoSwimming.png',
    'fitness':  'assets/images/courtoFitness.png',
    'arcade':   'assets/images/courtoArcade.png',
  };

  static const Map<String, IconData> _planTypeIcon = {
    'chess':    Icons.grid_on_rounded,
    'academy':  Icons.directions_run,
    'swimming': Icons.pool,
    'fitness':  Icons.fitness_center,
    'arcade':   Icons.sports_esports,
  };

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();

  bool      _loading = false;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _plans     = List<Map<String, dynamic>>.from(widget.plans);
    _planIndex = widget.initialIndex.clamp(0, _plans.length - 1);
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
    _initDuration();
    _refreshPlan();
    _prefillFromAccount();
  }

  /// The account holder is almost always the member, so the two fields they
  /// would otherwise retype are filled in. Both stay editable: a parent
  /// subscribing for someone else needs to be able to overwrite them, and the
  /// member details are stored per subscription, not taken from the account.
  void _prefillFromAccount() {
    final user = AuthService.userData;
    if (user == null) return;

    _nameCtrl.text = user['full_name']?.toString() ?? '';
    // Digits only, matching the field's input formatter. _normalisePhone
    // accepts the stored 218XXXXXXXXX form as-is.
    _phoneCtrl.text =
        (user['phone_number']?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
  }

  /// Re-reads the selected plan so places-left and prices are current. Silent
  /// on failure: what we already have is only slightly stale, and a purchase
  /// is validated server-side regardless.
  Future<void> _refreshPlan() async {
    final id = _plan['id'];
    if (id == null) return;

    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final res = await http.get(
        Uri.parse('${apiUrl}users/getGymById/$id'),
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      if (data['data'] == null || !mounted) return;

      setState(() {
        _plans[_planIndex] = Map<String, dynamic>.from(data['data']);
      });
    } catch (_) {
      // Keep what we were handed.
    }
  }

  void _initDuration() {
    final p = _plan;
    if (_toDouble(p['monthly_price'])   != null) { _durationType = 'monthly';   return; }
    if (_toDouble(p['quarterly_price']) != null) { _durationType = 'quarterly'; return; }
    if (_toDouble(p['annual_price'])    != null) { _durationType = 'annual';    return; }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool get isEnglish => Localizations.localeOf(context).languageCode == 'en';

  String get _imagePath {
    final type = (_plan['type'] ?? '').toString().toLowerCase();
    return _planTypeImage[type] ?? 'assets/images/courtoDefaultHeader.jpg';
  }

  // ── Photos ────────────────────────────────────────────────────────────────
  // Real uploaded photos, from subscription_plan_images. The bundled asset
  // keyed off `type` is only the fallback now - it was never a picture of
  // this particular place.
  List<String> get _images => ((_plan['images'] as List<dynamic>?) ?? [])
      .map((e) => e.toString())
      .where((e) => e.isNotEmpty)
      .toList();

  String _imageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = dotenv.env['API_URL'] ?? '';
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return "$trimmed${raw.startsWith('/') ? raw : '/$raw'}";
  }

  // ── Places ────────────────────────────────────────────────────────────────
  // max_seats null means the gym does not cap membership, which is different
  // from "no places left" - the two must not collapse into the same display.
  int? get _maxSeats => int.tryParse(_plan['max_seats']?.toString() ?? '');
  int get _seatsLeft => int.tryParse(_plan['available_seats']?.toString() ?? '') ?? 0;
  bool get _isFull => _maxSeats != null && _seatsLeft <= 0;

  double? get _selectedPrice {
    final p = _plan;
    switch (_durationType) {
      case 'monthly':   return _toDouble(p['monthly_price']);
      case 'quarterly': return _toDouble(p['quarterly_price']);
      case 'annual':    return _toDouble(p['annual_price']);
    }
    return null;
  }

  double? _toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());

  bool _hasDuration(String d) {
    switch (d) {
      case 'monthly':   return _toDouble(_plan['monthly_price'])   != null;
      case 'quarterly': return _toDouble(_plan['quarterly_price']) != null;
      case 'annual':    return _toDouble(_plan['annual_price'])     != null;
    }
    return false;
  }

  String _durationLabel(String d) {
    if (isEnglish) {
      switch (d) {
        case 'monthly':   return 'Monthly';
        case 'quarterly': return 'Quarterly';
        case 'annual':    return 'Annual';
      }
    } else {
      switch (d) {
        case 'monthly':   return 'شهري';
        case 'quarterly': return 'ربع سنوي';
        case 'annual':    return 'سنوي';
      }
    }
    return d;
  }

  // ── Phone normalisation ───────────────────────────────────────────────────
  /// Accepts:
  ///   9XXXXXXXX  (9 digits)  → prepend 218  → 2189XXXXXXXX
  ///   09XXXXXXXX (10 digits) → strip 0, prepend 218 → 2189XXXXXXXX
  ///   2189XXXXXXXX (12 digits) → keep as-is
  /// Returns null if the result is not a valid 12-digit Libyan number.
  String? _normalisePhone(String raw) {
    String v = raw.trim();

    if (v.startsWith('09') && v.length == 10) {
      v = '218${v.substring(1)}'; // 09X… → 218 9X…
    } else if (v.startsWith('9') && v.length == 9) {
      v = '218$v';                // 9X… → 218 9X…
    }

    if (!v.startsWith('2189')) return null;
    if (v.length != 12)        return null;
    return v;
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final normalisedPhone = _normalisePhone(_phoneCtrl.text);
    if (normalisedPhone == null) {
      _showSnack(isEnglish ? 'Invalid phone number' : 'رقم الهاتف غير صحيح');
      return;
    }

    setState(() => _loading = true);
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final token  = AuthService.token;

      final response = await http.post(
        Uri.parse('${apiUrl}users/purchaseSubscription'),
        headers: {
          'x-api-key': '${dotenv.env['API_KEY']}',
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan_id':       _plan['id'],
          'duration_type': _durationType,
          'full_name':     _nameCtrl.text.trim(),
          'phone_number':  normalisedPhone,
          // gender / school / grade / birth_date are no longer collected. All
          // four columns are nullable and users_purchase_subscription takes
          // null for them; a gym only needs a name and a number.
        }),
      );

      final body = jsonDecode(response.body);
  

      if (response.statusCode == 200 && body['success'] == true) {
        _showSnack(
          isEnglish ? 'Subscription successful!' : 'تم الاشتراك بنجاح!',
          success: true,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.popAndPushNamed(context, '/subscriptionsPage');
      } else {
        _showSnack(body['error'] ?? (isEnglish ? 'Something went wrong' : 'حدث خطأ'));
      }
    } catch (_) {
      _showSnack(isEnglish ? 'Network error' : 'خطأ في الاتصال');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: success ? Colors.green[700] : Colors.red[700],
      behavior:        SnackBarBehavior.floating,
    ));
  }

  // ── Switch plan ───────────────────────────────────────────────────────────
  void _switchPlan(int index) {
    if (index == _planIndex) return;
    setState(() {
      _planIndex = index;
      _initDuration();
    });
    // The newly selected plan carries the same stale places count as the one
    // just left, so it gets the same refresh.
    _refreshPlan();
    _fadeCtrl
      ..reset()
      ..forward();
  }

  // =========================================================================
  // Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final en    = isEnglish;
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final title = en
        ? (_plan['name_eng'] ?? _plan['name'] ?? '')
        : (_plan['name'] ?? '');
    final description = en
        ? (_plan['description_eng'] ?? _plan['description'] ?? '')
        : (_plan['description'] ?? '');

    return Directionality(
      textDirection: en ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [

              // ── Hero header ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: cs.primary,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _buildHeader(title.toString(), description.toString(), cs),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Plan selector — only shown when there are multiple plans
                      if (_plans.length > 1) ...[
                        _buildPlanSelector(en, cs),
                        const SizedBox(height: 24),
                      ],

                      if (_maxSeats != null) ...[
                        _buildSeatsBadge(en),
                        const SizedBox(height: 20),
                      ],

                      // More than one photo is worth a strip; a single one is
                      // already the hero above, and tapping that opens the
                      // viewer just the same.
                      if (_images.length > 1) ...[
                        _buildGallery(en),
                        const SizedBox(height: 24),
                      ],

                      _buildDurationSelector(en, cs),
                      const SizedBox(height: 24),

                      // Section divider
                      Row(children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            en ? 'Your details' : 'بياناتك',
                            style: TextStyle(
                              fontSize:   13,
                              color:      Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ]),
                      const SizedBox(height: 20),

                      _buildForm(en, cs),
                      const SizedBox(height: 32),

                      _buildPayButton(en, cs),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
 Widget _buildHeader(String title, String description, ColorScheme cs) {
  final ScrollController descController = ScrollController();
  final en       = isEnglish;
  final location = en
      ? (_plan['location_eng'] ?? _plan['location'] ?? '')
      : (_plan['location'] ?? '');

  // Coordinates, not the location text: the text is a free-typed description
  // ("behind the mosque"), which Google resolves to whatever it likes — or to
  // nothing. The gym's own lat/lng drops the pin exactly where it is, matching
  // what the field details page already does.
  Future<void> openMaps() async {
    final double? lat = double.tryParse(_plan['latitude']?.toString() ?? '');
    final double? lng = double.tryParse(_plan['longitude']?.toString() ?? '');
    final bool hasCoords =
        lat != null && lng != null && !(lat == 0 && lng == 0);

    // A plan saved without coordinates would otherwise open the map at 0,0 in
    // the Atlantic, so the text is still the fallback for that one case.
    final String query = hasCoords
        ? '$lat,$lng'
        : Uri.encodeComponent(location.toString());
    if (query.isEmpty) return;

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 450),
    child: Stack(
      key: ValueKey('header-$_planIndex'),
      fit: StackFit.expand,
      children: [

        // Background: the gym's own first photo, falling back to the bundled
        // asset for a plan that has none uploaded yet. Tapping opens the
        // viewer, so the hero is not a dead end when there is only one photo.
        if (_images.isNotEmpty)
          GestureDetector(
            onTap: () => _openViewer(0),
            child: Image.network(
              _imageUrl(_images.first),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                _imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: cs.primary),
              ),
            ),
          )
        else
          Image.asset(
            _imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: cs.primary),
          ),

        // Multi-stop gradient: dark top (for back button) → transparent middle → dark bottom
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              stops: const [0.0, 0.25, 0.55, 1.0],
              colors: [
                Colors.black.withOpacity(0.55), // dark behind back button
                Colors.transparent,
                Colors.black.withOpacity(0.30),
                Colors.black.withOpacity(0.82), // dark at bottom for text
              ],
            ),
          ),
        ),

        // Text content — pushed down with top padding so back button doesn't overlap
        Positioned(
          left: 16, right: 16, bottom: 16, top: 72, // top: 72 clears the back button
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Title with its own subtle text shadow only
              Text(
                title,
                style: const TextStyle(
                  fontSize:   24,
                  fontWeight: FontWeight.w900,
                  color:      Colors.white,
                  shadows: [
                    Shadow(blurRadius: 12, color: Colors.black),
                    Shadow(blurRadius: 4,  color: Colors.black),
                  ],
                ),
              ),

              // Location
              if (location.toString().isNotEmpty) ...[
  const SizedBox(height: 6),
  GestureDetector(
    onTap: openMaps,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on,
                  color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white54,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.open_in_new,
                  color: Colors.white60, size: 11),
            ],
          ),
        ),
      ),
    ),
  ),
],

              // Description — blurred frosted pill only around the text
if (description.isNotEmpty) ...[
  const SizedBox(height: 10),
  Flexible(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Stack(
  children: [
    Scrollbar(
      controller: descController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: descController,
        child: Text(description),
      ),
    ),

    // Fade indicator (VERY important UX signal)
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.6),
            ],
          ),
        ),
      ),
    ),
  ],
)
        ),
      ),
    ),
  ),
],
            ],
          ),
        ),
      ],
    ),
  );
}

  // ── Gallery ───────────────────────────────────────────────────────────────
  /// Opens the full-screen viewer at [index]. Reached from the hero and from
  /// any thumbnail, so a photo is always one tap from being readable.
  void _openViewer(int index) {
    if (_images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImageViewer(
          images: _images.map(_imageUrl).toList(),
          initialIndex: index,
          isEnglish: isEnglish,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Widget _buildGallery(bool en) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              en ? 'Photos' : 'الصور',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_images.length})',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openViewer(i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _imageUrl(_images[i]),
                  width: 180,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 180,
                    height: 130,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.broken_image,
                        color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Places left ───────────────────────────────────────────────────────────
  // Only rendered when the gym caps membership. available_seats comes from
  // plans_occupied_seats, which counts distinct members with a subscription
  // that has not lapsed - so a place frees up the day a membership expires.
  Widget _buildSeatsBadge(bool en) {
    final max = _maxSeats!;
    final left = _seatsLeft;
    final full = _isFull;
    // A quarter of capacity is the point where "nearly gone" is worth saying.
    final low = !full && left <= (max / 4).ceil();
    final color = full ? Colors.redAccent : (low ? Colors.deepOrange : Colors.teal);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(full ? Icons.block : Icons.event_seat_outlined,
                color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              full
                  ? (en ? 'Full' : 'مكتمل')
                  : (en ? '$left of $max left' : 'متبقي $left من $max'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan selector ─────────────────────────────────────────────────────────
  Widget _buildPlanSelector(bool en, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en ? 'Select plan' : 'اختر الخطة',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount:       _plans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final p        = _plans[i];
              final selected = i == _planIndex;
              final type     = (p['type'] ?? '').toString().toLowerCase();
              final icon     = _planTypeIcon[type] ?? Icons.star_outline;
              final label    = en
                  ? (p['name_eng'] ?? p['name'] ?? '')
                  : (p['name'] ?? '');

              return GestureDetector(
                onTap: () => _switchPlan(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 90,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color:        selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? cs.primary : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size:  26,
                        color: selected ? Colors.white : Colors.grey.shade500,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label.toString(),
                        maxLines:  2,
                        textAlign: TextAlign.center,
                        overflow:  TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Duration selector ─────────────────────────────────────────────────────
  Widget _buildDurationSelector(bool en, ColorScheme cs) {
    final options = ['monthly', 'quarterly', 'annual']
        .where(_hasDuration)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          en ? 'Subscription period' : 'مدة الاشتراك',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: options.asMap().entries.map((e) {
            final idx      = e.key;
            final d        = e.value;
            final selected = _durationType == d;
            final isLast   = idx == options.length - 1;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!selected) setState(() => _durationType = d);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.only(
                    right: en  && !isLast ? 8 : 0,
                    left:  !en && !isLast ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? cs.primary : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _durationLabel(d),
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  // ── Form ──────────────────────────────────────────────────────────────────
  Widget _buildForm(bool en, ColorScheme cs) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _field(
            controller: _nameCtrl,
            label: en ? 'Full name' : 'الاسم الكامل',
            icon:  Icons.person_outline,
            cs:    cs,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? (en ? 'Required' : 'مطلوب') : null,
          ),
          const SizedBox(height: 14),

          // Phone — smart normalisation
          TextFormField(
            controller:      _phoneCtrl,
            keyboardType:    TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText:  en ? 'Phone number' : 'رقم الهاتف',
              hintText:   en
                  ? 'e.g. 91XXXXXXX or 2189XXXXXXXX'
                  : 'مثال: 91XXXXXXX أو 2189XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined, color: cs.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:   BorderSide(color: cs.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return en ? 'Required' : 'مطلوب';
              if (_normalisePhone(v) == null) {
                return en
                    ? 'Enter a valid Libyan number (e.g. 91XXXXXXX)'
                    : 'أدخل رقماً ليبياً صحيحاً (مثال: 91XXXXXXX)';
              }
              return null;
            },
          ),

          // Gender, school, grade and birth date used to sit here. They belong
          // to the academy-style plans this page was first written for; a gym
          // needs a name and a number, and asking for more is friction plus
          // personal data nobody uses. The columns stay nullable.
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController     controller,
    required String                    label,
    required IconData                  icon,
    required ColorScheme               cs,
    TextInputType?                     keyboardType,
    List<TextInputFormatter>?          inputFormatters,
    String? Function(String?)?         validator,
  }) {
    return TextFormField(
      controller:      controller,
      keyboardType:    keyboardType,
      inputFormatters: inputFormatters,
      validator:       validator,
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: Icon(icon, color: cs.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }


  // ── Pay button ────────────────────────────────────────────────────────────
Widget _buildPayButton(bool en, ColorScheme cs) {
  final price    = _selectedPrice;
  final loggedIn = AuthService.isLoggedIn;

  // users_purchase_subscription refuses a full plan anyway; catching it here
  // means the user is told before filling the form, not after paying attention
  // to it. The button stays visible rather than hidden so the reason is on
  // screen next to the places card.
  final full = _isFull;

  final String label;
  if (full) {
    label = en ? 'No places left' : 'لا توجد أماكن متاحة';
  } else if (!loggedIn) {
    label = price != null
        ? (en
            ? 'Log in to pay LYD ${price.toStringAsFixed(2)}'
            : 'سجل دخولك لدفع ${price.toStringAsFixed(2)} د.ل')
        : (en ? 'Log in to subscribe' : 'سجل دخولك للاشتراك');
  } else {
    label = price != null
        ? (en
            ? 'Pay LYD ${price.toStringAsFixed(2)} from wallet'
            : 'ادفع ${price.toStringAsFixed(2)} د.ل من المحفظة')
        : (en ? 'Subscribe' : 'اشترك');
  }

  return SizedBox(
    width:  double.infinity,
    height: 54,
    child: ElevatedButton(
      // disabled when full, not logged in, or while loading
      onPressed: (full || !loggedIn || _loading) ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: (loggedIn && !full) ? cs.primary : Colors.grey.shade400,
        disabledBackgroundColor: (loggedIn && !full) ? null : Colors.grey.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: (loggedIn && !full) ? 4 : 0,
      ),
      child: _loading
          ? const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  loggedIn ? Icons.account_balance_wallet_outlined : Icons.lock_outline,
                  color: Colors.white,
                  size:  18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize:      16,
                    fontWeight:    FontWeight.w800,
                    color:         Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    ),
  );
}
}