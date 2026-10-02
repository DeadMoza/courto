import 'dart:convert';
import 'dart:ui' as ui;

import 'package:courto/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'subscription_plan_page.dart';

/// The gyms directory, reached from the landing page.
///
/// A gym is a subscription_plans row with type = 'gym', so everything here is
/// the plan the user would subscribe to - the same row the detail screen and
/// the existing subscribe flow both work on.
class GymsListPage extends StatefulWidget {
  const GymsListPage({super.key});

  @override
  State<GymsListPage> createState() => _GymsListPageState();
}

class _GymsListPageState extends State<GymsListPage> {
  List<Map<String, dynamic>> gyms = [];
  bool loading = true;
  String? errorMessage;
  String _search = '';

  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  ui.TextDirection get _dir =>
      _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    _fetchGyms();
  }

  Future<void> _fetchGyms() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final res = await http.get(
        Uri.parse("${apiUrl}users/getGyms"),
        headers: {
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}'
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (!mounted) return;
        setState(() {
          gyms = List<Map<String, dynamic>>.from(data["data"] ?? []);
          loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          errorMessage =
              _isEnglish ? "Couldn't load gyms" : "تعذر تحميل الصالات";
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        errorMessage = _isEnglish
            ? "Check your connection and try again"
            : "تحقق من اتصالك وحاول مرة أخرى";
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return gyms;
    final q = _search.toLowerCase();
    return gyms.where((g) {
      return (g['name'] ?? '').toString().toLowerCase().contains(q) ||
          (g['name_eng'] ?? '').toString().toLowerCase().contains(q) ||
          (g['location'] ?? '').toString().toLowerCase().contains(q) ||
          (g['location_eng'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  String _imageUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final base = apiUrl?.endsWith('/') == true
        ? apiUrl!.substring(0, apiUrl!.length - 1)
        : (apiUrl ?? '');
    return "$base${raw.startsWith('/') ? raw : '/$raw'}";
  }

  String _name(Map<String, dynamic> gym) => _isEnglish
      ? (gym['name_eng'] ?? gym['name'] ?? '').toString()
      : (gym['name'] ?? '').toString();

  String _location(Map<String, dynamic> gym) => _isEnglish
      ? (gym['location_eng'] ?? gym['location'] ?? '').toString()
      : (gym['location'] ?? '').toString();

  String _blurb(Map<String, dynamic> gym) => _isEnglish
      ? (gym['short_description_eng'] ?? gym['short_description'] ?? '')
          .toString()
      : (gym['short_description'] ?? '').toString();

  // Only meaningful when the gym caps membership; an uncapped gym showing
  // "null places left" would be worse than showing nothing.
  Widget? _seatsBadge(Map<String, dynamic> gym) {
    final max = int.tryParse(gym['max_seats']?.toString() ?? '');
    if (max == null) return null;

    final left = int.tryParse(gym['available_seats']?.toString() ?? '') ?? 0;
    final isFull = left <= 0;
    final isLow = !isFull && left <= (max / 4).ceil();
    final color =
        isFull ? Colors.redAccent : (isLow ? Colors.deepOrange : Colors.teal);

    final label = isFull
        ? (_isEnglish ? 'Full' : 'مكتمل')
        : (_isEnglish ? '$left of $max places' : 'متبقي $left من $max');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  Widget _buildGymCard(Map<String, dynamic> gym) {
    final images = (gym['images'] as List<dynamic>?) ?? [];
    final blurb = _blurb(gym);
    final location = _location(gym);
    final seats = _seatsBadge(gym);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          // The subscription page IS the gym page: photos, prices, places
          // left and the sign-up form in one screen.
          MaterialPageRoute(
            builder: (_) => SubscriptionPlanPage(plans: [gym], initialIndex: 0),
          ),
        );
        // Places may have been taken while the detail screen was open.
        if (mounted) _fetchGyms();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: images.isNotEmpty
                  ? Image.network(
                      _imageUrl(images.first.toString()),
                      width: double.infinity,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(gym),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    textDirection: _dir,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                            textDirection: _dir,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (blurb.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      textDirection: _dir,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _isEnglish
                              ? "${gym['monthly_price']} LYD / month"
                              : "${gym['monthly_price']} د.ل / شهرياً",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textDirection: _dir,
                        ),
                      ),
                      if (seats != null) seats,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 170,
      color: Colors.grey.shade300,
      child: Icon(Icons.fitness_center,
          size: 48, color: Colors.grey.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        appBar: buildHomeAppBar(context),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                textDirection: _dir,
                decoration: InputDecoration(
                  hintText:
                      _isEnglish ? "Search gyms..." : "ابحث عن صالة...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                ),
              ),
            ),
            Expanded(
              child: loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  textDirection: _dir,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchGyms,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(_isEnglish
                                      ? 'Retry'
                                      : 'إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                _isEnglish
                                    ? "No gyms available yet"
                                    : "لا توجد صالات متاحة حالياً",
                                textDirection: _dir,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : RefreshIndicator(
                              color: Theme.of(context).colorScheme.primary,
                              onRefresh: _fetchGyms,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildGymCard(_filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
